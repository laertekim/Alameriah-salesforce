import { LightningElement, api, track, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';
//apex classes
import getAllBuildingsResidentialProperty from '@salesforce/apex/DealJunkTableController.getAllBuildingsResidentialProperty';
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
import Status__FIELD from '@salesforce/schema/Building__c.Status__c';
import Unit_Type__FIELD from '@salesforce/schema/Building__c.Unit_Type__c';
import LocationAndVisibility__FIELD from '@salesforce/schema/Building__c.LocationAndVisibility__c';
import Tower_Name__FIELD from '@salesforce/schema/Building__c.Tower_Name__c';
import Tower_No__FIELD from '@salesforce/schema/Building__c.Tower_No__c';
import TowerCode__FIELD from '@salesforce/schema/Building__c.TowerCode__c';
import Level__FIELD from '@salesforce/schema/Building__c.Level__c';
import Apartment_Type__FIELD from '@salesforce/schema/Building__c.Apartment_Type__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import SITE from '@salesforce/schema/Opportunity.Site__c';
import getOpportunity from '@salesforce/apex/DealJunkTableController.getOpportunity';
//----------------------------------------------------------------

import Opport_OBJECT from '@salesforce/schema/Opportunity';
export default class DealJunctionObjectTable extends NavigationMixin(LightningElement) {
	
    @track isModalOpen = false;
    @track isModalOpen2 = false;
    @track error;
    @track isResidentialProperty = false;
    @track isResidential = false;
    showPagination = false;
    
    @track objectDTO ;
    @api recordId;
	recordEditId;
	recordDeleteId;
    booleItem = false;
    @track records;
    @track dealRecords;
	siteId;
	
    @wire(getObjectInfo, { objectApiName: DEAL_BUILDING_OBJECT })
    DealBuildInfo;
	
    @wire(getObjectInfo, { objectApiName: BUILDING_OBJECT })
    BuildInfo;

	recordTypeId;
	@wire(getObjectInfo, { objectApiName: BUILDING_OBJECT})
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === 'Residential Property' || rtis[rti].name === 'Residential' );
        }
    }


	async LoadOpportunityData() {
    	const opp = await getOpportunity({ recordId: this.recordId });
    	this.siteId = opp.Site__c;
    	this.isResidentialProperty = opp.RecordType && opp.RecordType.Name === 'Residential Property';
    	this.isResidential = opp.RecordType && opp.RecordType.Name === 'Residential';
	}

    get villaAreaLabel() {
        return this.isResidential ? 'Unit Area' : 'Villa Area';
    }
    get villaSellableAreaLabel() {
        return this.isResidential ? 'Unit Sellable Area / Sqm' : 'Villa Sellable Area / Sqm';
    }
    get villaSellableAmountLabel() {
        return this.isResidential ? 'Unit Sellable Amount' : 'Villa Sellable Amount';
    }


    //---------------------------Location And Visibility-------------------------------

    valueLocationAndVisibilityPicklist = '';
    optionsLocationAndVisibility = []; 
    
    @wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: LocationAndVisibility__FIELD
        }
    )
    locationAndVisibilityInfoValue({error, data}) {
        if (data) {
            console.log('data.values '+data.values);
            let optionsValue = data.values;
            this.optionsLocationAndVisibility = [{ label: '--None--', value: "" }];
            optionsValue.forEach(opt => this.optionsLocationAndVisibility.push(opt));
            console.log('this.optionsLocationAndVisibility '+this.optionsLocationAndVisibility);
        } else if (error) {
            console.log(error);
        }
    }

    handleChangeLocationAndVisibility(event) {
        this.valueLocationAndVisibilityPicklist = event.detail.value;
        this.updatePage();
    }

	
	//---------------------------Status Picklist-------------------------------
	valueStatusPicklist = '';
	optionsStatusPicklist = []; 
	
	@wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Status__FIELD
        }
    )
    statusInfoValue({error, data}) {
        if (data) {
	
            let optionsValue = data.values;
			this.optionsStatusPicklist = [{ label: '--None--', value: "" }];
			optionsValue.forEach(opt => this.optionsStatusPicklist.push(opt));
	
        } else if (error) {
            console.log(error);
        }
    }

	handleChangeStatus(event) {
        this.valueStatusPicklist = event.detail.value;
		this.updatePage();
    }

	
	//---------------------------Unit No-------------------------------
    valueUnitNo = '';
    handleChangeUnitNo(event) {
        this.valueUnitNo = event.detail.value;   
        this.updatePage();
        
    }

    //Unit Type Picklist
    valueUnitType = '';
    optionsUnitType = [];
    @wire(getPicklistValues,
        {
            recordTypeId: '$recordTypeId',
            fieldApiName: Unit_Type__FIELD
        }
    )
    unitTypeInfoValue({error, data}) {
        if (data) {
            let optionsValue = data.values;
            this.optionsUnitType = [{ label: '--None--', value: "" }];
            optionsValue.forEach(opt => this.optionsUnitType.push(opt));
        } else if (error) {
            console.log(error);
        }
    }

    handleChangeUnitType(event) {
        this.valueUnitType = event.detail.value;
        this.updatePage();
    }


	//---------------------------Tower Name-------------------------------
    valueTowerName = '';
    optionsTowerName = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Tower_Name__FIELD })
    towerNameInfoValue({error, data}) {
        if (data) {
            this.optionsTowerName = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.optionsTowerName.push(opt));
        }
    }
    handleChangeTowerName(event) {
        this.valueTowerName = event.detail.value;
        this.updatePage();
    }

    //---------------------------Tower No-------------------------------
    valueTowerNo = '';
    optionsTowerNo = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Tower_No__FIELD })
    towerNoInfoValue({error, data}) {
        if (data) {
            this.optionsTowerNo = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.optionsTowerNo.push(opt));
        }
    }
    handleChangeTowerNo(event) {
        this.valueTowerNo = event.detail.value;
        this.updatePage();
    }

    //---------------------------Tower Code-------------------------------
    valueTowerCode = '';
    optionsTowerCode = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: TowerCode__FIELD })
    towerCodeInfoValue({error, data}) {
        if (data) {
            this.optionsTowerCode = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.optionsTowerCode.push(opt));
        }
    }
    handleChangeTowerCode(event) {
        this.valueTowerCode = event.detail.value;
        this.updatePage();
    }

    //---------------------------Level-------------------------------
    valueLevel = '';
    optionsLevel = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Level__FIELD })
    levelInfoValue({error, data}) {
        if (data) {
            this.optionsLevel = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.optionsLevel.push(opt));
        }
    }
    handleChangeLevel(event) {
        this.valueLevel = event.detail.value;
        this.updatePage();
    }

    //---------------------------Apartment Type-------------------------------
    valueApartmentType = '';
    optionsApartmentType = [];
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Apartment_Type__FIELD })
    apartmentTypeInfoValue({error, data}) {
        if (data) {
            this.optionsApartmentType = [{ label: '--None--', value: '' }];
            data.values.forEach(opt => this.optionsApartmentType.push(opt));
        }
    }
    handleChangeApartmentType(event) {
        this.valueApartmentType = event.detail.value;
        this.updatePage();
    }

	//------------------PICKLIST END-----------------------------------

	handleSuccess() {
		const evt = new ShowToastEvent({
			title: "Success!",
			message: "The record has been successfully saved.",
			variant: "success",
		});

		this.dispatchEvent(evt);
		this.updatePage();
		//eval("$A.get('e.force:refreshView').fire();");
		this.isModalOpen = false;
		
		
		//
	}

	updatePage() {
		this.getData();
	}
	   
	handleError() {
		const evt = new ShowToastEvent({
			title: "Error!",
			message: "An error occurred while attempting to save the record. " ,
			variant: "error",
		});
		this.dispatchEvent(evt);
		this.isModalOpen = false;
	}
	handleCancel() {
		this.isModalOpen = false;
	}

    handleErrorFormSubmit(event) {
        // Handle error logic
        console.error('Record Edit Form Error:', JSON.stringify(event.detail));
        
        // Use lightning-messages in HTML to display the error automatically, 
        // or manually display a toast
        const toastEvent = new ShowToastEvent({
            title: 'Error submitting record',
            message: event.detail.detail, // General message
            variant: 'error'
        });
        this.dispatchEvent(toastEvent);
    }
    //--------------------------Show data-----------------------------
    connectedCallback() {
		//wait for the record to be loaded using loadopportunitydata method to get the site name before calling getdata method
		this.LoadOpportunityData().then(() => {
			this.updatePage();
		});
	
		
	}

	resetData() {
		this.value = '';
		this.updatePage();
	}

    getData() {	
		this.objectDTO = {
			fieldAndValue : {
				Center_name__c :  this.siteId,
				LocationAndVisibility__c : this.valueLocationAndVisibilityPicklist,
				Unit_No__c : this.valueUnitNo,
				Status__c : this.valueStatusPicklist,
				Unit_Type__c : this.valueUnitType,
				Tower_Name__c : this.valueTowerName,
				Tower_No__c : this.valueTowerNo,
				TowerCode__c : this.valueTowerCode,
				Level__c : this.valueLevel,
				Apartment_Type__c : this.valueApartmentType
			}
		};
        //pass the parameters to the method as lwc needs specify the parameter name

		getAllBuildingsResidentialProperty({objectDTO : JSON.stringify(this.objectDTO)}) 
			.then(result => {
				this.records = result;
					
			})
			.catch(error => {
				this.error = error;
				this.records = undefined;
			});

            getRelatedDealBuilding({ dealRecordId : this.recordId }) 
			.then(result => {
				this.dealRecords = result;
					
			})
			.catch(error => {
				this.error = error;
				this.dealRecords = undefined;
				
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
		
		this.updatePage();
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
						
						errormessageitem = errormessageitem+item.Status__c;
						
					}
				}
				//---------------------------------------------//
            let selection = checked.join(', ');
            
			if(errormessageitem != ''){
			
				this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error adding Units',
                        message: 'Please select available unit!',
                        variant: 'error'
                    })
                );
				/**/
			}else{
			
				createJunctionObject({dealRecordId : this.recordId,
					stringBuildingsIds : selection})
				.then(result => {            
				this.showSuccessEvent();
				this.updatePage();
				eval("$A.get('e.force:refreshView').fire();");
				})
				.catch(error => {
				this.error = error;
			
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
			this.isModalOpen = true;
		}
		
        closeModal() {
			this.isModalOpen = false;
		}

		submitDetails() {

			this.isModalOpen = false;
			return this.updatePage();
		}

		deleteRecordModal(event) {
			this.recordDeleteId = event.target.dataset.id;
			// to open modal set isModalOpen tarck value as true
			
			this.isModalOpen2 = true;
		}

		closeModal2() {
			// to close modal set isModalOpen tarck value as false
			this.isModalOpen2 = false;
		}
		
		submitDetails2() {
			// to close modal set isModalOpen tarck value as false
			//Add your code to call apex method or do some processing
			
			deleteRecord(this.recordDeleteId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Record deleted',
                        variant: 'success'
                    })
                );
				
				this.updatePage();
                
            })
            .catch(error => {
				
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });

			this.isModalOpen2 = false;
			this.updatePage();
		}
}