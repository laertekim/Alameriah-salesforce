import { LightningElement, api, track, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';
//apex classes
import getAllBuildings from '@salesforce/apex/DealJunkTableController.getAllBuildings';
import getRelatedDealBuilding from '@salesforce/apex/DealJunkTableController.getRelatedDealBuilding';
import createJunctionObject from '@salesforce/apex/DealJunkTableController.createJunctionObject';
import getOpportunity from '@salesforce/apex/DealJunkTableController.getOpportunity';
import getFieldConfig from '@salesforce/apex/DealJunkTableController.getFieldConfig';
//Other
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
//picklist
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import BUILDING_OBJECT from '@salesforce/schema/Building__c';
import DEAL_BUILDING_OBJECT from '@salesforce/schema/Deal_Building__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import ZONE_FIELD from '@salesforce/schema/Building__c.Zone__c';
import Lease_Phases__FIELD from '@salesforce/schema/Building__c.Lease_Phases__c';
import Tower_Name__FIELD from '@salesforce/schema/Building__c.Tower_Name__c';
import Building_Type__FIELD from '@salesforce/schema/Building__c.Building_Type__c';
import Status__FIELD from '@salesforce/schema/Building__c.Status__c';
import Level__FIELD from '@salesforce/schema/Building__c.Level__c';
import Unit_No__FIELD from '@salesforce/schema/Building__c.Unit_No__c';
import View__FIELD from '@salesforce/schema/Building__c.View__c';
//----------------------------------------------------------------
import Tower_Name__DBFIELD from '@salesforce/schema/Deal_Building__c.Tower_Name__c';
export default class DealJunctionObjectTable extends NavigationMixin(LightningElement) {
	value6_5 = '';
	value11 = '';
	value12 = '';
	value13 = '';
	towernamefield = Tower_Name__DBFIELD;
    showPagination = false;
    @api recordId;
	recordEditId;
	recordDeleteId;
    booleItem = false;
    @track records;
    @track DealRecords;
	@track isOffices = false;
	@track opportunityRecordTypeName = '';
	_buildingObjectInfoData = null;
	// Dynamic column config from metadata
	@track _columns = [];            // [{ apiName, label }]
	@track _processedRecords = [];   // Building__c rows for the Units table
	@track _processedDealRecords = []; // Deal_Building__c rows for the Deal Units table

	@wire(getObjectInfo, { objectApiName: DEAL_BUILDING_OBJECT })
    DealBuildInfo;
	@wire(getObjectInfo, { objectApiName: BUILDING_OBJECT })
    BuildInfo;

	recordTypeId;
	@wire(getObjectInfo, { objectApiName: BUILDING_OBJECT})
    getobjectInfo(result) {
        if (result.data) {
			this._buildingObjectInfoData = result.data;
			this._resolveRecordTypeId();
        }
    }

	_resolveRecordTypeId() {
		if (!this._buildingObjectInfoData) return;
		const rtis = this._buildingObjectInfoData.recordTypeInfos;
		const rtName = this.opportunityRecordTypeName || 'Offices';
		this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === rtName);
		console.log('this.recordTypeId ' + this.recordTypeId + ' for ' + rtName);
	}

	async LoadOpportunityData() {
		const opp = await getOpportunity({ recordId: this.recordId });
		this.opportunityRecordTypeName = (opp.RecordType && opp.RecordType.Name) ? opp.RecordType.Name : 'Offices';
		this.isOffices = opp.RecordType && opp.RecordType.Name === 'Offices';
		this._resolveRecordTypeId();
		// Load visible columns from metadata — only Is_Visible__c = true records are returned
		const configs = await getFieldConfig({ recordTypeName: this.opportunityRecordTypeName });
		this._columns = (configs || []).map(c => ({ apiName: c.Field_API_Name__c, label: c.Column_Label__c }));
	}

	// Returns true if a field is in the visible column list (for filter comboboxes)
	_hasColumn(apiName) {
		return this._columns.some(c => c.apiName === apiName);
	}

	// Returns the label for a specific field (for filter combobox labels)
	_getColumnLabel(apiName, defaultLabel) {
		const col = this._columns.find(c => c.apiName === apiName);
		return col ? col.label : defaultLabel;
	}

	// Builds processed row array from raw Salesforce records using current _columns
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

	// Filter combobox visibility — show only if the field is a visible column
	get showZoneFilter() { return this._hasColumn('Zone__c'); }
	get showTowerNameFilter() { return this._hasColumn('Tower_Name__c'); }
	get showBuildingTypeFilter() { return this._hasColumn('Building_Type__c'); }
	get showStatusFilter() { return this._hasColumn('Status__c'); }
	get showLevelFilter() { return this._hasColumn('Level__c'); }
	get showUnitNoFilter() { return this._hasColumn('Unit_No__c'); }
	get showViewFilter() { return this._hasColumn('View__c'); }

	// Filter combobox labels — use metadata label if present
	get zoneLabel() { return this._getColumnLabel('Zone__c', 'Zone'); }
	get towerNameLabel() { return this._getColumnLabel('Tower_Name__c', 'Tower Name'); }
	get buildingTypeLabel() { return this._getColumnLabel('Building_Type__c', 'Building Type'); }
	get levelLabel() { return this._getColumnLabel('Level__c', 'Level'); }
	get unitNoLabel() { return this._getColumnLabel('Unit_No__c', 'Unit No'); }
	get viewLabel() { return this._getColumnLabel('View__c', 'View'); }

	//---------------------------ZONE-------------------------------
	value = '';
	options1 = [];

	@track isModalOpen = false;
	@track isModalOpen2 = false;

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: ZONE_FIELD
        }
    )
    LTFinfoValue1({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
            let optionsValue = data.values;
			this.options1 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options1.push(opt));
			console.log('this.options1 '+this.options1);
        } else if (error) {
            console.log(error);
        }
    }

	handleChange1(event) {
        this.value = event.detail.value;
		this.getData();
    }
	//----------------------------Lease Phases------------------------
	value2 = '';
	options2 = [];

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Lease_Phases__FIELD
        }
    )
    LTFinfoValue2({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
			let optionsValue = data.values;
			this.options2 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options2.push(opt));
        } else if (error) {
            console.log(error);
        }
    }

	handleChange2(event) {
        this.value2 = event.detail.value;
		this.getData();
    }

	//---------------------------Tower Name-------------------------------
	value3 = '';
	options3 = [];

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Tower_Name__FIELD
        }
    )
    LTFinfoValue3({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
            let optionsValue = data.values;
			this.options3 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options3.push(opt));
			console.log('this.options1 '+this.options3);
        } else if (error) {
            console.log(error);
        }
    }

	handleChange3(event) {
        this.value3 = event.detail.value;
		this.getData();
    }

	//---------------------------Building Type-------------------------------
	value4 = '';
	options4 = [];

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Building_Type__FIELD
        }
    )
    LTFinfoValue4({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
            let optionsValue = data.values;
			this.options4 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options4.push(opt));
			console.log('this.options4 '+this.options4);
        } else if (error) {
            console.log(error);
        }
    }

	handleChange4(event) {
        this.value4 = event.detail.value;
		this.getData();
    }

	//---------------------------Status-------------------------------
	value5 = '';
	options5 = [];

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Status__FIELD
        }
    )
    LTFinfoValue5({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
            let optionsValue = data.values;
			this.options5 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options5.push(opt));
			console.log('this.options5 '+this.options5);
        } else if (error) {
            console.log(error);
        }
    }

	handleChange5(event) {
        this.value5 = event.detail.value;
		this.getData();
    }

	//---------------------------Level-------------------------------
	value6 = '';
	options6 = [];

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Level__FIELD
        }
    )
    LTFinfoValue6({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
            let optionsValue = data.values;
			this.options6 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options6.push(opt));
			console.log('this.options5 '+this.options6);
        } else if (error) {
            console.log(error);
        }
    }

	handleChange6(event) {
        this.value6 = event.detail.value;
		this.getData();
    }

	//---------------------------Unit No-------------------------------
	value7 = '';
	options7 = [];

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Unit_No__FIELD
        }
    )
    LTFinfoValue7({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
            let optionsValue = data.values;
			this.options7 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options7.push(opt));
			console.log('this.options5 '+this.options7);
        } else if (error) {
            console.log(error);
        }
    }

	handleChange7(event) {
        this.value7 = event.detail.value;
		this.getData();
    }

	//---------------------------View-------------------------------
	value8 = '';
	options8 = [];

	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: View__FIELD
        }
    )
    LTFinfoValue8({error, data}) {
        if (data) {
			console.log('data.values '+data.values);
            let optionsValue = data.values;
			this.options8 = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.options8.push(opt));
			console.log('this.options5 '+this.options8);
        } else if (error) {
            console.log(error);
        }
    }

	handleChange8(event) {
        this.value8 = event.detail.value;
		this.getData();
    }

	//------------------PICKLIST END-----------------------------------

	handleSuccess() {
		const evt = new ShowToastEvent({
			title: "Success!",
			message: "The record has been successfully saved.",
			variant: "success",
		});
		this.dispatchEvent(evt);
		refreshApex(this.getData());
		this.isModalOpen = false;
	}

	updatePage() {
		refreshApex(this.getData());
	}

	handleError() {
		const evt = new ShowToastEvent({
			title: "Error!",
			message: "An error occurred while attempting to save the record.",
			variant: "error",
		});
		this.dispatchEvent(evt);
		this.isModalOpen = false;
	}
	handleCancel() {
		this.isModalOpen = false;
	}
    //--------------------------Show data-----------------------------
    async connectedCallback() {
		console.log('ZONE_FIELD '+ZONE_FIELD);
		await this.LoadOpportunityData();
		this.getData();
	}

	resetData() {
		this.value = '';
		this.getData();
	}

    getData() {
		console.log('this.value2 '+this.value);
		getAllBuildings({ dealRecordId : this.recordId, zone : this.value, leasePhases : this.value2, towerName : this.value3, buildingType : this.value4, status : this.value5, level : this.value6, apartmentType : this.value6_5, unitNo : this.value7, viewValue : this.value8, unitType : this.value11, retailCategory : this.value12, typeOfActivity : this.value13})
			.then(result => {
				console.log( 'Fetched Data ' + JSON.stringify( result[0] ) );
				this.records = result.map(r => ({ ...r, selected: this.booleItem }));
				this._processedRecords = this._processRecords(this.records, this.booleItem);
				console.log('this.records: ', this.records);
			})
			.catch(error => {
				this.error = error;
				this.records = undefined;
				this._processedRecords = [];
				console.log('getData error: ', error);
			});

        getRelatedDealBuilding({ dealRecordId : this.recordId })
			.then(result => {
				console.log( 'Fetched Data21 ' + JSON.stringify( result[0] ) );
				this.DealRecords = result;
				this._processedDealRecords = this._processRecords(result);
				console.log('this.DealRecords: ', this.DealRecords);
			})
			.catch(error => {
				this.error = error;
				this.DealRecords = undefined;
				this._processedDealRecords = [];
				console.log('getData error: ', error);
			});
	}

    //--------------------------Navigate Record Link-----------------------------
    navigateToRecordPage(event) {
		let recordIdToRedirect = event.currentTarget.dataset.id;
		this[NavigationMixin.GenerateUrl]({
			type: 'standard__recordPage',
			attributes: {
				recordId: recordIdToRedirect,
				objectApiName: 'Building__c',
				actionName: 'view'
			}
		}).then(url => {
			 window.open(url);
		});
	}

    //--------------------------Selected Records logic-----------------------------
    handleChange(event) {
		if(event.target.checked == true){
			this.booleItem = true;
			for(let item of this.records){
				item.selected = true;
			}
			for(let row of this._processedRecords){
				row.selected = true;
			}
		}else{
			this.booleItem = false;
			for(let item of this.records){
				item.selected = false;
			}
			for(let row of this._processedRecords){
				row.selected = false;
			}
		}
    }

    oneChange(event) {
		const id = event.target.dataset.id;
		const checked = event.target.checked;
		for(let item of this.records){
			if(item.Id == id){
				item.selected = checked;
			}
		}
		for(let row of this._processedRecords){
			if(row.id == id){
				row.selected = checked;
			}
		}
	}

    //--------------------------Update Selected Records-----------------------------
    getAllId(event) {
        const checked = Array.from(
                this.template.querySelectorAll('lightning-input')
            )
                .filter(element => element.checked)
                .map(element => element.dataset.id);

			let errormessageitem = '';
			for(let item of this.records){
				if(item.selected && item.Status__c != 'Available Units'){
					console.log(item.selected+' ------ '+item.Status__c);
					errormessageitem = errormessageitem+item.Status__c;
					console.log(' ------ '+errormessageitem);
				}
			}
            let selection = checked.join(', ');
            console.log('selection: ', selection);
			if(errormessageitem != ''){
				console.log('selection123: ');
				this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error adding Units',
                        message: 'Please select available unit!',
                        variant: 'error'
                    })
                );
			}else{
				console.log('selection321: ');
				createJunctionObject({dealRecordId : this.recordId,
					stringBuildingsIds : selection})
				.then(result => {
				this.showSuccessEvent();
				this.getData();
				eval("$A.get('e.force:refreshView').fire();");
				})
				.catch(error => {
				this.error = error;
				console.log('update community error: ', error);
				});
			}
        }

        showSuccessEvent() {
            const event = new ShowToastEvent({
                            title: 'Success!',
                            variant: 'success',
                            message: 'Products were Unpublished successfully.',
            });
        }

		openModal(event) {
			this.recordEditId = event.target.dataset.id;
			console.log('event.target.dataset.id '+event.target.dataset.id);
			this.isModalOpen = true;
		}
		closeModal() {
			this.isModalOpen = false;
		}
		submitDetails() {
			console.log('tttetttetetetet');
			this.isModalOpen = false;
			return refreshApex(this.getData());
		}

		deleteRecordModal(event) {
			this.recordDeleteId = event.target.dataset.id;
			console.log('event.target.dataset.id '+event.target.dataset.id);
			this.isModalOpen2 = true;
		}

		closeModal2() {
			this.isModalOpen2 = false;
		}
		@track error;
		submitDetails2() {
			console.log('TESTTESTETS11');
			deleteRecord(this.recordDeleteId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
				console.log('TESTTESTETS2211');
				this.getData();
            })
            .catch(error => {
				console.log('TESTTESTETS24433');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
			console.log('TESTTESTETS23322');
			this.isModalOpen2 = false;
		}
}