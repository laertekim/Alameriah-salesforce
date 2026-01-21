import { LightningElement, api, track, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';
//apex classes
import getAllBuildings from '@salesforce/apex/DealJunkTableController.getAllBuildings';
import getRelatedDealBuilding from '@salesforce/apex/DealJunkTableController.getRelatedDealBuilding';
import createJunctionObject from '@salesforce/apex/DealJunkTableController.createJunctionObject';
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
import Opport_OBJECT from '@salesforce/schema/Opportunity';
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
    @track dealRecords;
	@wire(getObjectInfo, { objectApiName: DEAL_BUILDING_OBJECT })
    DealBuildInfo;
	@wire(getObjectInfo, { objectApiName: BUILDING_OBJECT })
    BuildInfo;

	recordTypeId;
	@wire(getObjectInfo, { objectApiName: BUILDING_OBJECT})
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Offices');
			console.log('this.recordTypeId1 '+this.recordTypeId);
        }
    }
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
            //this.options2 = data.values;
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
		//eval("$A.get('e.force:refreshView').fire();");
		this.isModalOpen = false;
		
		
		//
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
    connectedCallback() {
		/*this.readyToPublish = 'Ready to be Published';
		this.productState = 'All';
		this.sortBy = 'ProductCode';
		this.orderType = 'ASC';*/
		console.log('ZONE_FIELD '+ZONE_FIELD);
		this.getData();
	}

	resetData() {
		/*this.readyToPublish = 'Ready to be Published';
		this.productState = 'All';
		this.sortBy = 'ProductCode';
		this.orderType = 'ASC';*/
		this.value = '';
		this.getData();
	}

    getData() {
		console.log('this.value2 '+this.value);		
		getAllBuildings({ dealRecordId : this.recordId, zone : this.value, Lease_Phases : this.value2, Tower_Name : this.value3, Building_Type : this.value4, Status : this.value5, Level : this.value6, Apartment_Type : this.value6_5, Unit_No : this.value7, View : this.value8, Unit_Type : this.value11, Retail_Category : this.value12, Type_of_Activity : this.value13}) 
			.then(result => {
				console.log( 'Fetched Data ' + JSON.stringify( result[0] ) );
					this.records = result;
					console.log('this.records: ', this.records);
					for(let item of this.records){
						item.selected = this.booleItem;
					}
			})
			.catch(error => {
				this.error = error;
				this.records = undefined;
				console.log('getData error: ', error);
			});

            getRelatedDealBuilding({ dealRecordId : this.recordId }) 
			.then(result => {
				console.log( 'Fetched Data21 ' + JSON.stringify( result[0] ) );
					this.DealRecords = result;
					console.log('this.records: ', this.DealRecords);
					
			})
			.catch(error => {
				this.error = error;
				this.DealRecords = undefined;
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
            /*,
            state: {
                nooverride: 1,
                navigationLocation: 'DETAIL',
                backgroundContext: '/lightning/r/Building__c/'+recordIdToRedirect+'/view'
                //backgroundContext: back_url
            }*/
		}).then(url => {
			 window.open(url);
		});
	}

    //--------------------------Selected Records logic-----------------------------
    handleChange(event) {
        let i;
        let checkboxes = this.template.querySelectorAll('[title="checkboxTitle"]');
		
		if(event.target.checked == true){
			for(let item of this.records){
				this.booleItem = true;
				item.selected = this.booleItem;
			}
		}else{
			for(let item of this.records){
				this.booleItem = false;
				item.selected = this.booleItem;
			}
		}
		
		this.getData();
    }


    oneChange(event) {
		if(event.target.checked){
			for(let item of this.records){
				if(item.Id == event.target.dataset.id){
					item.selected = true;
				}
			}
		}else{
			for(let item of this.records){
				if(item.Id == event.target.dataset.id){
					item.selected = false;
				}
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

				//--------------------------------------------//
				let errormessageitem = '';
				for(let item of this.records){
					if(item.selected && item.Status__c != 'Available Units'){
						console.log(item.selected+' ------ '+item.Status__c);
						errormessageitem = errormessageitem+item.Status__c;
						console.log(' ------ '+errormessageitem);
					}
				}
				//---------------------------------------------//
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
				/**/
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
                
				//return refreshApex(this.getData());
				//this.getData();
				//eval("$A.get('e.force:refreshView').fire();");
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
			// to open modal set isModalOpen tarck value as true
			console.log('event.target.dataset.id '+event.target.dataset.id);
			this.isModalOpen = true;
		}
		closeModal() {
			// to close modal set isModalOpen tarck value as false
			this.isModalOpen = false;
		}
		submitDetails() {
			// to close modal set isModalOpen tarck value as false
			//Add your code to call apex method or do some processing
			console.log('tttetttetetetet');
			this.isModalOpen = false;
			return refreshApex(this.getData());
		}

		deleteRecordModal(event) {
			this.recordDeleteId = event.target.dataset.id;
			// to open modal set isModalOpen tarck value as true
			console.log('event.target.dataset.id '+event.target.dataset.id);
			this.isModalOpen2 = true;
		}

		closeModal2() {
			// to close modal set isModalOpen tarck value as false
			this.isModalOpen2 = false;
		}
		@track error;
		submitDetails2() {
			// to close modal set isModalOpen tarck value as false
			//Add your code to call apex method or do some processing
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
				//eval("$A.get('e.force:refreshView').fire();");
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