import { LightningElement, api, wire, track } from 'lwc';
import getRecord from '@salesforce/apex/ControllerCreateDeal.getBulding';
import createDeal from '@salesforce/apex/ControllerCreateDeal.createDeal';
import createDealWithPaymentPlan from '@salesforce/apex/ControllerCreateDeal.createDealWithPaymentPlan';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import PAYMENTPLAN_OBJECT from '@salesforce/schema/PaymentPlan__c';
import getAllPaymentPlans from '@salesforce/apex/ControllerCreateDeal.getAllPaymentPlans';

export default class CreateDealFromBuilding extends LightningElement {
    @api recordId;
    @track record;
    name;
    closeDate;
    stage = 'Available Units';
    tenantsName;
    @track showPaymentPlan = false;
    @track paymentPlans;
    @track paymentPlan;
    @track recordTypeName; // Store the record type name from the building
    @track paymentPlanRecordTypeId; // Store the matching PaymentPlan record type ID

    // Getter to check if this is a Residential Property
    get isResidentialProperty() {
        return this.recordTypeName === 'Residential Property';
    }

    @wire(getRecord, {oppId: '$recordId'})
    wiredAccount({ error, data }) {
        if (data) {
            console.log('Building data:', JSON.stringify(data));
            this.record = data;
            // Extract the record type name from the building record
            this.recordTypeName = data.RecordType?.Name;
            console.log('Building Record Type Name:', this.recordTypeName);
            
            // Now that we have the building's record type, we can find the matching PaymentPlan record type
            this.findMatchingPaymentPlanRecordType();
        } else if (error) {
            console.log('Something went wrong:', error);
        }
    }

    // Wire to get PaymentPlan object info
    @wire(getObjectInfo, { objectApiName: PAYMENTPLAN_OBJECT })
    paymentPlanObjectInfo({ error, data }) {
        if (data) {
            this.paymentPlanRecordTypeInfos = data.recordTypeInfos;
            console.log('PaymentPlan Record Types available:', Object.keys(data.recordTypeInfos).map(key => ({
                id: key,
                name: data.recordTypeInfos[key].name
            })));
            
            // If we already have the building's record type name, find the matching PaymentPlan record type
            if (this.recordTypeName) {
                this.findMatchingPaymentPlanRecordType();
            }
        } else if (error) {
            console.error('Error getting PaymentPlan object info:', error);
        }
    }

    // Method to find the PaymentPlan record type that matches the building's record type
    findMatchingPaymentPlanRecordType() {
        if (this.recordTypeName && this.paymentPlanRecordTypeInfos) {
            // Find the PaymentPlan record type with the same name as the building's record type
            const matchingRecordType = Object.keys(this.paymentPlanRecordTypeInfos).find(
                (rti) => this.paymentPlanRecordTypeInfos[rti].name === this.recordTypeName
            );
            
            if (matchingRecordType) {
                this.paymentPlanRecordTypeId = matchingRecordType;
                console.log('Found matching PaymentPlan Record Type ID:', this.paymentPlanRecordTypeId);
                
                // Load payment plans for this record type
                this.loadPaymentPlans();
            } else {
                console.log('No matching PaymentPlan record type found for:', this.recordTypeName);
                this.showPaymentPlan = false;
            }
        }
    }

    get options() {
        return [
            { label: 'Available Units', value: 'Available Units' },
            { label: 'Offered', value: 'Offered' },
            { label: 'Booked', value: 'Booked' },
            { label: 'Booked & Paid', value: 'Booked & Paid' },
            { label: 'Signed & Paid', value: 'Signed & Paid' },
            { label: 'Closed Lost', value: 'Closed Lost' },
        ];
    }

    loadPaymentPlans() {
        console.log('Loading payment plans with record type ID:', this.paymentPlanRecordTypeId);
        
        if (!this.paymentPlanRecordTypeId) {
            console.log('No record type ID available for payment plans');
            this.showPaymentPlan = false;
            return;
        }
        
        getAllPaymentPlans({recordTypeId: this.paymentPlanRecordTypeId})
            .then(result => {
                console.log('Payment plans result:', result);
                if (result && result.length > 0) {
                    this.paymentPlans = result.map(paymentPlan => ({
                        label: paymentPlan.Name,
                        value: paymentPlan.Id
                    }));
                    this.showPaymentPlan = true;
                } else {
                    console.log('No payment plans found for this record type');
                    this.showPaymentPlan = false;
                }
            })
            .catch(error => {
                console.log('Error loading payment plans:', JSON.stringify(error));
                this.showPaymentPlan = false;
            });
    }
    
    handleChangePaymentPlan(event) {
        this.paymentPlan = event.detail.value;
    }

    handleChangeName(event) {
        this.name = event.detail.value;
    }

    handleChangeCloseDate(event) {
        this.closeDate = event.detail.value;
    }

    handleChangeStage(event) {
        this.stage = event.detail.value;
    }

    handleAccountSelection(event) {
        this.tenantsName = event.detail.value;
        console.log('Selected tenant:', this.tenantsName);
    }

    handleClickCancel(event) {
        console.log('Cancel');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleClickSave(event) {
        try {
            if (this.checkFields()) {
                if (this.isResidentialProperty && this.paymentPlan) {
                    // Use the method with payment plan for Residential Property
                    createDealWithPaymentPlan({
                        buildId: this.recordId, 
                        name: this.name,
                        closeDate: this.closeDate,
                        stage: this.stage,
                        recordTypeName: this.recordTypeName,
                        siteId: this.record.Center_Name__c,
                        tenantsName1: this.tenantsName.toString(), 
                        paymentPlanId: this.paymentPlan
                    }).then(() => {
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.showSuccessToast();
                    }).catch(error => {
                        console.error('Error creating deal with payment plan:', error);
                        this.showErrorToast('Failed to create deal with payment plan');
                    });
                } else {
                    // Use the regular method for other record types
                    createDeal({
                        buildId: this.recordId, 
                        name: this.name,
                        closeDate: this.closeDate,
                        stage: this.stage,
                        recordTypeName: this.recordTypeName,
                        siteId: this.record.Center_Name__c,
                        tenantsName1: this.tenantsName.toString()
                    }).then(() => {
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.showSuccessToast();
                    }).catch(error => {
                        console.error('Error creating deal:', error);
                        this.showErrorToast('Failed to create deal');
                    });
                }
            } else {
                this.showErrorToast('Required fields must be filled.');
            }
        } catch (e) {
            console.log('Error creating deal:', JSON.stringify(e));
            this.showErrorToast('An unexpected error occurred');
        }
    }

    checkFields() {
        try {
            return this.name && 
                   this.closeDate && 
                   this.stage && 
                   this.tenantsName 
                  
        } catch (e) {
            return false;
        }
    }

    showSuccessToast() {
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Deal created successfully',
            variant: 'success'
        });
        this.dispatchEvent(event);
    }

    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        });
        this.dispatchEvent(event);
    }
}