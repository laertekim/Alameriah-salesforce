import { LightningElement, api, wire, track } from 'lwc';
import getRecord from '@salesforce/apex/ControllerCreateDeal.getBulding';
import createDeal from '@salesforce/apex/ControllerCreateDeal.createDeal';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreateDealFromBuilding extends LightningElement {
    @api recordId;
    record;
    name;
    closeDate;
    stage = 'Available Units';
    tenantsName;
    
    @wire(getRecord, {oppId: '$recordId'})
    wiredAccount({ error, data }) {
        if (data) {
            console.log(JSON.stringify('data[0] '+data));
            this.record = data;
        } else if (error) {
            console.log('Something went wrong:', error);
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
        console.log(this.tenantsName);
    }

    handleClickCancel(event) {
        console.log('Cancel');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleClickSave(event) {
        //window.location.reload();
        
        try{
            if(this.name != undefined 
                && this.closeDate != undefined
                && this.stage != undefined
                && this.tenantsName != undefined){
                    console.log('without error');
                createDeal({buildId: this.recordId, 
                    name: this.name,
                    closeDate : this.closeDate,
                    stage : this.stage,
                    recordTypeName : this.record.RecordType.Name,
                    siteId : this.record.Center_Name__c,
                    tenantsName1 : this.tenantsName.toString()});
                    console.log('clickSaveTest13 ');
                    console.log('clickSaveTest22 '+this.recordId,);
                    console.log('name '+this.name);
                    console.log('closeDate '+this.closeDate);
                    console.log('stage '+this.stage);
                    console.log('tenantsName '+this.tenantsName);
                    this.dispatchEvent(new CloseActionScreenEvent());
            }else{
                console.log('error message');
                this.showToast();
            }
            
            //window.location.reload();
        }catch (e) {
            //this.dispatchEvent(new CloseActionScreenEvent());
            //window.location.reload();
        }
        console.log('testreload');
        //window.location.reload();
    }

    showToast() {
        console.log('show toast');
        const event = new ShowToastEvent({
            title: 'Contact',
            message: 'Required fields must be filled. ',
            variant: 'error'
        });
        this.dispatchEvent(event);
    }
}