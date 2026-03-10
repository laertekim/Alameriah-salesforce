import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
// Apex
import getAllBuildings from '@salesforce/apex/DealJunkTableController.getAllBuildings';
import getRelatedDealBuilding from '@salesforce/apex/DealJunkTableController.getRelatedDealBuilding';
import createJunctionObject from '@salesforce/apex/DealJunkTableController.createJunctionObject';
import getFieldConfigForDeal from '@salesforce/apex/DealJunkTableController.getFieldConfigForDeal';
// Other
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
// Object / picklist wiring
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import BUILDING_OBJECT from '@salesforce/schema/Building__c';
import DEAL_BUILDING_OBJECT from '@salesforce/schema/Deal_Building__c';
import ZONE_FIELD from '@salesforce/schema/Building__c.Zone__c';
import Level__FIELD from '@salesforce/schema/Building__c.Level__c';
import Status__FIELD from '@salesforce/schema/Building__c.Status__c';
import Unit_No__FIELD from '@salesforce/schema/Building__c.Unit_No__c';
import Unit_Type__FIELD from '@salesforce/schema/Building__c.Unit_Type__c';
import Retail_Category__FIELD from '@salesforce/schema/Building__c.Retail_Category__c';
import TypeOfActivity__FIELD from '@salesforce/schema/Building__c.Type_of_Activity__c';
import Tower_Name__DBFIELD from '@salesforce/schema/Deal_Building__c.Tower_Name__c';

export default class RetailDealJunctionObjectTable extends NavigationMixin(LightningElement) {
    towernamefield = Tower_Name__DBFIELD;
    @api recordId;
    recordEditId;
    recordDeleteId;
    booleItem = false;
    @track records;
    @track DealRecords;
    _buildingObjectInfoData = null;
    @track _columns = [];
    @track _processedRecords = [];
    @track _processedDealRecords = [];
    opportunityRecordTypeName = null;

    @wire(getObjectInfo, { objectApiName: DEAL_BUILDING_OBJECT })
    DealBuildInfo;

    // Resolve Building__c record type Id for picklist wiring (matches the Opportunity record type)
    recordTypeId;
    @wire(getObjectInfo, { objectApiName: BUILDING_OBJECT })
    getobjectInfo(result) {
        if (result.data) {
            this._buildingObjectInfoData = result.data;
            this._resolveRecordTypeId();
        }
    }

    _resolveRecordTypeId() {
        if (!this._buildingObjectInfoData || !this.opportunityRecordTypeName) return;
        const rtis = this._buildingObjectInfoData.recordTypeInfos;
        this.recordTypeId = Object.keys(rtis).find(id => rtis[id].name === this.opportunityRecordTypeName);
    }

    async connectedCallback() {
        try {
            const config = await getFieldConfigForDeal({ opportunityId: this.recordId });
            this.opportunityRecordTypeName = config?.recordTypeName;
            console.log('Opportunity RecordType:', this.opportunityRecordTypeName); // Debug
            this._resolveRecordTypeId();
            this._columns = (config?.columns || []).map(c => ({ apiName: c.Field_API_Name__c, label: c.Column_Label__c }));
        } catch (e) {
            console.error('Error getting field config:', e);
        }
        this.getData();
    }

    _hasColumn(apiName) {
        return this._columns.some(c => c.apiName === apiName);
    }

    _getColumnLabel(apiName, defaultLabel) {
        const col = this._columns.find(c => c.apiName === apiName);
        return col ? col.label : defaultLabel;
    }

    _processRecords(rawRecords, defaultSelected) {
        return (rawRecords || []).map(r => ({
            id: r.Id,
            selected: defaultSelected !== undefined ? defaultSelected : (r.selected || false),
            cells: this._columns.map(col => ({
                key: col.apiName,
                value: r[col.apiName] !== undefined && r[col.apiName] !== null ? String(r[col.apiName]) : ''
            }))
        }));
    }

    // Filter visibility (controlled by Field_Display_Config__mdt)
    get showZoneFilter()           { return this._hasColumn('Zone__c'); }
    get showLevelFilter()          { return this._hasColumn('Level__c'); }
    get showStatusFilter()         { return this._hasColumn('Status__c'); }
    get showUnitNoFilter()         { return this._hasColumn('Unit_No__c'); }
    get showUnitTypeFilter()       { return this._hasColumn('Unit_Type__c'); }
    get showRetailCategoryFilter() { return this._hasColumn('Retail_Category__c'); }
    get showTypeOfActivityFilter() { return this._hasColumn('Type_of_Activity__c'); }

    // Filter labels
    get zoneLabel()           { return this._getColumnLabel('Zone__c', 'Zone'); }
    get levelLabel()          { return this._getColumnLabel('Level__c', 'Level'); }
    get unitNoLabel()         { return this._getColumnLabel('Unit_No__c', 'Unit No'); }
    get unitTypeLabel()       { return this._getColumnLabel('Unit_Type__c', 'Unit Type'); }
    get retailCategoryLabel() { return this._getColumnLabel('Retail_Category__c', 'Retail Category'); }
    get typeOfActivityLabel() { return this._getColumnLabel('Type_of_Activity__c', 'Type of Activity'); }

    // Zone
    value = '';
    options1 = [];
    @track isModalOpen = false;
    @track isModalOpen2 = false;

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: ZONE_FIELD })
    LTFinfoValue1({ error, data }) {
        if (data) {
            this.options1 = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.options1.push(opt));
        }
    }
    handleChange1(event) { this.value = event.detail.value; this.getData(); }

    // Level
    value6 = '';
    options6 = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Level__FIELD })
    LTFinfoValue6({ error, data }) {
        if (data) {
            this.options6 = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.options6.push(opt));
        }
    }
    handleChange6(event) { this.value6 = event.detail.value; this.getData(); }

    // Status
    value5 = '';
    options5 = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Status__FIELD })
    LTFinfoValue5({ error, data }) {
        if (data) {
            this.options5 = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.options5.push(opt));
        }
    }
    handleChange5(event) { this.value5 = event.detail.value; this.getData(); }

    // Unit No
    value7 = '';
    options7 = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Unit_No__FIELD })
    LTFinfoValue7({ error, data }) {
        if (data) {
            this.options7 = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.options7.push(opt));
        }
    }
    handleChange7(event) { this.value7 = event.detail.value; this.getData(); }

    // Unit Type
    value11 = '';
    options11 = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Unit_Type__FIELD })
    LTFinfoValue11({ error, data }) {
        if (data) {
            this.options11 = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.options11.push(opt));
        }
    }
    handleChange11(event) { this.value11 = event.detail.value; this.getData(); }

    // Retail Category
    value12 = '';
    options12 = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Retail_Category__FIELD })
    LTFinfoValue12({ error, data }) {
        if (data) {
            this.options12 = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.options12.push(opt));
        }
    }
    handleChange12(event) { this.value12 = event.detail.value; this.getData(); }

    // Type of Activity
    value13 = '';
    options13 = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: TypeOfActivity__FIELD })
    LTFinfoValue13({ error, data }) {
        if (data) {
            this.options13 = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.options13.push(opt));
        }
    }
    handleChange13(event) { this.value13 = event.detail.value; this.getData(); }

    //----------------------------------------------------------------

    handleSuccess() {
        this.dispatchEvent(new ShowToastEvent({ title: 'Success!', message: 'The record has been successfully saved.', variant: 'success' }));
        refreshApex(this.getData());
        this.isModalOpen = false;
    }

    updatePage() { refreshApex(this.getData()); }

    handleError() {
        this.dispatchEvent(new ShowToastEvent({ title: 'Error!', message: 'An error occurred while attempting to save the record.', variant: 'error' }));
        this.isModalOpen = false;
    }

    handleCancel() { this.isModalOpen = false; }

    getData() {
        // getAllBuildings filters by RecordType.Name (Retail) AND Center_Name__c (from Opportunity.Site__c)
        // automatically — no extra params needed beyond the filter values
        getAllBuildings({
            dealRecordId: this.recordId,
            zone: this.value,
            leasePhases: '',
            towerName: '',
            buildingType: '',
            status: this.value5,
            level: this.value6,
            apartmentType: '',
            unitNo: this.value7,
            viewValue: '',
            unitType: this.value11,
            retailCategory: this.value12,
            typeOfActivity: this.value13
        })
        .then(result => {
            this.records = result.map(r => ({ ...r, selected: this.booleItem }));
            this._processedRecords = this._processRecords(this.records, this.booleItem);
        })
        .catch(error => {
            this.error = error;
            this.records = undefined;
            this._processedRecords = [];
        });

        getRelatedDealBuilding({ dealRecordId: this.recordId })
        .then(result => {
            this.DealRecords = result;
            this._processedDealRecords = this._processRecords(result);
        })
        .catch(error => {
            this.error = error;
            this.DealRecords = undefined;
            this._processedDealRecords = [];
        });
    }

    navigateToRecordPage(event) {
        let recordIdToRedirect = event.currentTarget.dataset.id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: { recordId: recordIdToRedirect, objectApiName: 'Building__c', actionName: 'view' }
        }).then(url => { window.open(url); });
    }

    handleChange(event) {
        if (event.target.checked) {
            this.booleItem = true;
            for (let item of this.records) item.selected = true;
            for (let row of this._processedRecords) row.selected = true;
        } else {
            this.booleItem = false;
            for (let item of this.records) item.selected = false;
            for (let row of this._processedRecords) row.selected = false;
        }
    }

    oneChange(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;
        for (let item of this.records) if (item.Id == id) item.selected = checked;
        for (let row of this._processedRecords) if (row.id == id) row.selected = checked;
    }

    getAllId() {
        const checked = Array.from(this.template.querySelectorAll('lightning-input'))
            .filter(el => el.checked)
            .map(el => el.dataset.id);

        let errormessageitem = '';
        for (let item of this.records) {
            if (item.selected && item.Status__c !== 'Available Units') {
                errormessageitem += item.Status__c;
            }
        }

        if (errormessageitem !== '') {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error adding Units', message: 'Please select available unit!', variant: 'error' }));
            return;
        }

        createJunctionObject({ dealRecordId: this.recordId, stringBuildingsIds: checked.join(', ') })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success!', message: 'Units added successfully.', variant: 'success' }));
            this.getData();
            eval("$A.get('e.force:refreshView').fire();");
        })
        .catch(error => { this.error = error; });
    }

    openModal(event) { this.recordEditId = event.target.dataset.id; this.isModalOpen = true; }
    closeModal()     { this.isModalOpen = false; }
    submitDetails()  { this.isModalOpen = false; return refreshApex(this.getData()); }

    deleteRecordModal(event) { this.recordDeleteId = event.target.dataset.id; this.isModalOpen2 = true; }
    closeModal2()            { this.isModalOpen2 = false; }

    @track error;
    submitDetails2() {
        deleteRecord(this.recordDeleteId)
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Record deleted', variant: 'success' }));
            this.getData();
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error deleting record', message: error.body.message, variant: 'error' }));
        });
        this.isModalOpen2 = false;
    }
}