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
import Apartment_Type__FIELD from '@salesforce/schema/Building__c.Apartment_Type__c';
import Unit_Type__FIELD from '@salesforce/schema/Building__c.Unit_Type__c';
import Retail_Category__FIELD from '@salesforce/schema/Building__c.Retail_Category__c';
import TypeOfActivity__FIELD from '@salesforce/schema/Building__c.Type_of_Activity__c';
import LocationAndVisibility__FIELD from '@salesforce/schema/Building__c.LocationAndVisibility__c';

export default class UnifiedDealJunctionTable extends NavigationMixin(LightningElement) {
    @api recordId;
    @api recordTypeName = 'Residential'; // Default: Residential, Offices, or Retail
    @api columnConfig; // JSON string or object defining which columns to show
    
    towernamefield;
    showPagination = false;
    recordEditId;
    recordDeleteId;
    booleItem = false;
    @track records;
    @track dealRecords;
    configInitialized = false;
    
    @wire(getObjectInfo, { objectApiName: DEAL_BUILDING_OBJECT })
    DealBuildInfo;
    
    @wire(getObjectInfo, { objectApiName: BUILDING_OBJECT })
    BuildInfo;

    recordTypeId;
    @track isModalOpen = false;
    @track isModalOpen2 = false;
    @track error;
    
    // Dynamic filter values - will be populated based on config
    filterValues = {};
    filterOptions = {};
    
    // Column configuration
    @track dealColumns = [];
    @track unitColumns = [];
    @track filterFields = [];
    
    // All possible picklist options (populated by wire adapters)
    optionsZone = [];
    optionsLeasePhases = [];
    optionsTowerName = [];
    optionsBuildingType = [];
    optionsStatus = [];
    optionsLevel = [];
    optionsUnitNo = [];
    optionsView = [];
    optionsApartmentType = [];
    optionsUnitType = [];
    optionsRetailCategory = [];
    optionsTypeOfActivity = [];
    optionsLocationAndVisibility = [];
    
    // Field value mappings
    valueZone = '';
    valueLeasePhases = '';
    valueTowerName = '';
    valueBuildingType = '';
    valueStatus = '';
    valueLevel = '';
    valueUnitNo = '';
    valueView = '';
    valueApartmentType = '';
    valueUnitType = '';
    valueRetailCategory = '';
    valueTypeOfActivity = '';
    valueLocationAndVisibility = '';

    @wire(getObjectInfo, { objectApiName: BUILDING_OBJECT})
    getobjectInfo(result) {
        if (result.data) {
            const rtis = result.data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find((rti) => rtis[rti].name === this.recordTypeName);
            if (this.recordTypeId && !this.configInitialized) {
                this.configInitialized = true;
                this.initializeConfiguration();
                // getData will be called after picklist values are loaded
            }
        }
    }

    connectedCallback() {
        // Configuration will be initialized after recordTypeId is set in wire adapter
    }

    initializeConfiguration() {
        // Parse column config if provided as string
        let config = this.columnConfig;
        if (typeof config === 'string' && config.trim()) {
            try {
                config = JSON.parse(config);
                console.log('Parsed custom config:', config);
            } catch (e) {
                console.error('Error parsing columnConfig:', e);
                console.error('Config string:', this.columnConfig);
                config = null;
            }
        }

        // If no config provided or parsing failed, use default based on record type
        if (!config) {
            config = this.getDefaultConfig(this.recordTypeName);
            console.log('Using default config for:', this.recordTypeName);
        }

        // Set up columns and filters
        this.dealColumns = config.dealColumns || [];
        this.unitColumns = config.unitColumns || [];
        this.filterFields = config.filterFields || [];

        console.log('Initialized with dealColumns:', this.dealColumns.length);
        console.log('Initialized with unitColumns:', this.unitColumns.length);
        console.log('Initialized with filterFields:', this.filterFields.length);
    }

    getDefaultConfig(recordType) {
        const configs = {
            'Residential': {
                dealColumns: [
                    { fieldApiName: 'Zone__c', label: 'Zone', type: 'text' },
                    { fieldApiName: 'Tower_Name__c', label: 'Tower<br>Name', type: 'text' },
                    { fieldApiName: 'Level__c', label: 'Level', type: 'text' },
                    { fieldApiName: 'Apartment_Type__c', label: 'Apartment<br>Type', type: 'text' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', type: 'text' },
                    { fieldApiName: 'View__c', label: 'View', type: 'text' },
                    { fieldApiName: 'Unit_Area_Sqm__c', label: 'Unit<br>Area/Sqm', type: 'number' },
                    { fieldApiName: 'Min_Weighted__c', label: 'Min.<br>Weighted', type: 'number' },
                    { fieldApiName: 'Min_Weighted_Rate__c', label: 'Min.<br>Weighted Rate', type: 'number' },
                    { fieldApiName: 'Client_Min_Price_SAR__c', label: 'Client Min<br>Price SAR', type: 'currency' },
                    { fieldApiName: 'Ask_Weighted__c', label: 'Ask.<br>Weighted', type: 'number' },
                    { fieldApiName: 'Ask_Weighted_Rate__c', label: 'Ask.<br>Weighted Rate', type: 'number' },
                    { fieldApiName: 'Client_Asking_Price_SAR__c', label: 'Client Asking<br>Price SAR', type: 'currency' },
                    { fieldApiName: 'Total_Selling_Price_SAR__c', label: 'Total<br>Selling<br>Price SAR', type: 'currency' }
                ],
                unitColumns: [
                    { fieldApiName: 'Status__c', label: 'Status', type: 'text' },
                    { fieldApiName: 'Zone__c', label: 'Zone', type: 'text' },
                    { fieldApiName: 'Tower_Name__c', label: 'Tower<br>Name', type: 'text' },
                    { fieldApiName: 'Level__c', label: 'Level', type: 'text' },
                    { fieldApiName: 'Apartment_Type__c', label: 'Apartment Type', type: 'text' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', type: 'text' },
                    { fieldApiName: 'View__c', label: 'View', type: 'text' },
                    { fieldApiName: 'Unit_Area_Sqm__c', label: 'Unit<br>Area/Sqm', type: 'number' },
                    { fieldApiName: 'Min_Weighted__c', label: 'Min.<br>Weighted', type: 'number' },
                    { fieldApiName: 'Min_Weighted_Rate__c', label: 'Min.<br>Weighted Rate', type: 'number' },
                    { fieldApiName: 'Client_Min_Price_SAR__c', label: 'Client Min<br>Price SAR', type: 'currency' },
                    { fieldApiName: 'Ask_Weighted__c', label: 'Ask.<br>Weighted', type: 'number' },
                    { fieldApiName: 'Ask_Weighted_Rate__c', label: 'Ask.<br>Weighted Rate', type: 'number' },
                    { fieldApiName: 'Client_Asking_Price_SAR__c', label: 'Client Asking<br>Price SAR', type: 'currency' }
                ],
                filterFields: [
                    { fieldApiName: 'Zone__c', label: 'Zone', schemaField: 'Building__c.Zone__c' },
                    { fieldApiName: 'Tower_Name__c', label: 'Tower Name', schemaField: 'Building__c.Tower_Name__c' },
                    { fieldApiName: 'Status__c', label: 'Status', schemaField: 'Building__c.Status__c' },
                    { fieldApiName: 'Level__c', label: 'Level/Floor', schemaField: 'Building__c.Level__c' },
                    { fieldApiName: 'Apartment_Type__c', label: 'Apartment Type', schemaField: 'Building__c.Apartment_Type__c' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', schemaField: 'Building__c.Unit_No__c' },
                    { fieldApiName: 'View__c', label: 'View', schemaField: 'Building__c.View__c' }
                ]
            },
            'Offices': {
                dealColumns: [
                    { fieldApiName: 'Zone__c', label: 'Zone', type: 'text' },
                    { fieldApiName: 'Tower_Name__c', label: 'Tower<br>Name', type: 'text' },
                    { fieldApiName: 'Level__c', label: 'Level', type: 'text' },
                    { fieldApiName: 'Building_Type__c', label: 'Building<br>Type', type: 'text' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', type: 'text' },
                    { fieldApiName: 'View__c', label: 'View', type: 'text' },
                    { fieldApiName: 'Unit_Area_Sqm_NSA__c', label: 'Unit Area<br>Sqm (NSA)', type: 'number' },
                    { fieldApiName: 'Lobby_Area_Sqm__c', label: 'Lobby Area<br>Ground Floor', type: 'number' },
                    { fieldApiName: 'Service_Area_Sqm__c', label: 'Service<br>Area Sqm', type: 'number' },
                    { fieldApiName: 'Terrace_Area_Sqm__c', label: 'Terrace<br>Area Sqm', type: 'number' },
                    { fieldApiName: 'Total_Unit_Area_Sqm__c', label: 'Gross Area<br>Size Sqm', type: 'number' },
                    { fieldApiName: 'Total_Leasable_Area_Sqm__c', label: 'Total Leasable<br>Area Sqm', type: 'number' },
                    { fieldApiName: 'Leasing_Rate_Sqm_SAR__c', label: 'Leasing Rate/<br>Sqm SAR', type: 'currency' },
                    { fieldApiName: 'Price_Sqm_SAR_Lobby__c', label: 'Price Sqm<br>SAR /Lobby', type: 'currency' },
                    { fieldApiName: 'Price_Sqm_SAR_Services__c', label: 'Price Sqm SAR/<br>Services', type: 'currency' },
                    { fieldApiName: 'Price_Sqm_SAR_Terraces__c', label: 'Price Sqm SAR/<br>Terraces', type: 'currency' },
                    { fieldApiName: 'Total_NSA__c', label: 'Total (NSA)', type: 'currency' },
                    { fieldApiName: 'Total_Prices_Lobby__c', label: 'Total Prices<br>(Lobby Areas)', type: 'currency' },
                    { fieldApiName: 'Total_Prices_Services_Areas__c', label: 'Total Prices<br>(Services Areas)', type: 'currency' },
                    { fieldApiName: 'Total_Prices_Terraces_Areas__c', label: 'Total Prices<br>(Terraces Areas)', type: 'currency' },
                    { fieldApiName: 'Gross_Leasable_Amount_SAR__c', label: 'Gross Leasable<br>Amount SAR', type: 'currency' },
                    { fieldApiName: 'Total_Selling_Price_SAR__c', label: 'Total<br>Selling<br>Price SAR', type: 'currency' }
                ],
                unitColumns: [
                    { fieldApiName: 'Status__c', label: 'Status', type: 'text' },
                    { fieldApiName: 'Zone__c', label: 'Zone', type: 'text' },
                    { fieldApiName: 'Tower_Name__c', label: 'Tower<br>Name', type: 'text' },
                    { fieldApiName: 'Level__c', label: 'Level', type: 'text' },
                    { fieldApiName: 'Building_Type__c', label: 'Building<br>Type', type: 'text' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', type: 'text' },
                    { fieldApiName: 'View__c', label: 'View', type: 'text' },
                    { fieldApiName: 'Unit_Area_Sqm_NSA__c', label: 'Unit Area<br>Sqm (NSA)', type: 'number' },
                    { fieldApiName: 'Lobby_Area_Sqm__c', label: 'Lobby Area<br>Ground Floor', type: 'number' },
                    { fieldApiName: 'Service_Area_Sqm__c', label: 'Service<br>Area Sqm', type: 'number' },
                    { fieldApiName: 'Terrace_Area_Sqm__c', label: 'Terrace<br>Area Sqm', type: 'number' },
                    { fieldApiName: 'Total_Unit_Area_Sqm__c', label: 'Gross Area<br>Size Sqm', type: 'number' },
                    { fieldApiName: 'Total_Leasable_Area_Sqm__c', label: 'Total Leasable<br>Area Sqm', type: 'number' },
                    { fieldApiName: 'Leasing_Rate_Sqm_SAR__c', label: 'Leasing Rate/<br>Sqm SAR', type: 'currency' },
                    { fieldApiName: 'Price_Sqm_SAR_Lobby__c', label: 'Price Sqm<br>SAR /Lobby', type: 'currency' },
                    { fieldApiName: 'Price_Sqm_SAR_Services__c', label: 'Price Sqm SAR/<br>Services', type: 'currency' },
                    { fieldApiName: 'Price_Sqm_SAR_Terraces__c', label: 'Price Sqm SAR/<br>Terraces', type: 'currency' },
                    { fieldApiName: 'Total_NSA__c', label: 'Total (NSA)', type: 'currency' },
                    { fieldApiName: 'Total_Prices_Lobby_Areas__c', label: 'Total Prices<br>(Lobby Areas)', type: 'currency' },
                    { fieldApiName: 'Total_Prices_Services_Areas__c', label: 'Total Prices<br>(Services Areas)', type: 'currency' },
                    { fieldApiName: 'Total_Prices_Terraces_Areas__c', label: 'Total Prices<br>(Terraces Areas)', type: 'currency' },
                    { fieldApiName: 'Gross_Leasable_Amount_SAR__c', label: 'Gross Leasable<br>Amount SAR', type: 'currency' },
                    { fieldApiName: 'Total_Selling_Price_SAR__c', label: 'Total<br>Selling<br>Price SAR', type: 'currency' },
                    { fieldApiName: 'Agent_Commission_8__c', label: 'Agent Commission 8%', type: 'currency' },
                    { fieldApiName: 'Edara_Commission_2__c', label: 'Edara Commission 2%', type: 'currency' }
                ],
                filterFields: [
                    { fieldApiName: 'Zone__c', label: 'Zone', schemaField: 'Building__c.Zone__c' },
                    { fieldApiName: 'Tower_Name__c', label: 'Tower Name', schemaField: 'Building__c.Tower_Name__c' },
                    { fieldApiName: 'Building_Type__c', label: 'Building Type', schemaField: 'Building__c.Building_Type__c' },
                    { fieldApiName: 'Status__c', label: 'Status', schemaField: 'Building__c.Status__c' },
                    { fieldApiName: 'Level__c', label: 'Level', schemaField: 'Building__c.Level__c' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', schemaField: 'Building__c.Unit_No__c' },
                    { fieldApiName: 'View__c', label: 'View', schemaField: 'Building__c.View__c' }
                ]
            },
            'Retail': {
                dealColumns: [
                    { fieldApiName: 'Level__c', label: 'Level', type: 'text' },
                    { fieldApiName: 'Zone__c', label: 'Zone', type: 'text' },
                    { fieldApiName: 'Unit_Type__c', label: 'Unit Type', type: 'text' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', type: 'text' },
                    { fieldApiName: 'Unit_Area_Sqm__c', label: 'Unit<br>Area/Sqm', type: 'number' },
                    { fieldApiName: 'Asking_Price__c', label: 'Asking Price', type: 'currency' },
                    { fieldApiName: 'Minimum_Annual_Rent__c', label: 'Minimum<br>Annual Rent', type: 'currency' },
                    { fieldApiName: 'Asking_Annual_Rent__c', label: 'Asking<br>Annual Rent', type: 'currency' },
                    { fieldApiName: 'Total_Selling_Price_SAR__c', label: 'Total<br>Selling<br>Price SAR', type: 'currency' }
                ],
                unitColumns: [
                    { fieldApiName: 'Status__c', label: 'Status', type: 'text' },
                    { fieldApiName: 'Level__c', label: 'Level', type: 'text' },
                    { fieldApiName: 'Zone__c', label: 'Zone', type: 'text' },
                    { fieldApiName: 'Unit_Type__c', label: 'Unit Type', type: 'text' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', type: 'text' },
                    { fieldApiName: 'Unit_Area_Sqm__c', label: 'Unit<br>Area/Sqm', type: 'number' },
                    { fieldApiName: 'Asking_Price__c', label: 'Asking Price', type: 'currency' },
                    { fieldApiName: 'Minimum_Annual_Rent__c', label: 'Minimum<br>Annual Rent', type: 'currency' },
                    { fieldApiName: 'Asking_Annual_Rent__c', label: 'Asking<br>Annual Rent', type: 'currency' }
                ],
                filterFields: [
                    { fieldApiName: 'Zone__c', label: 'Zone', schemaField: 'Building__c.Zone__c' },
                    { fieldApiName: 'Level__c', label: 'Level', schemaField: 'Building__c.Level__c' },
                    { fieldApiName: 'Unit_Type__c', label: 'Unit Type', schemaField: 'Building__c.Unit_Type__c' },
                    { fieldApiName: 'Unit_No__c', label: 'Unit No', schemaField: 'Building__c.Unit_No__c' },
                    { fieldApiName: 'Retail_Category__c', label: 'Retail Category', schemaField: 'Building__c.Retail_Category__c' },
                    { fieldApiName: 'Status__c', label: 'Status', schemaField: 'Building__c.Status__c' }
                ]
            }
        };

        return configs[recordType] || configs['Residential'];
    }

    // Wire adapters for all possible picklist fields
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: ZONE_FIELD })
    wiredZoneOptions({error, data}) {
        if (data) {
            this.optionsZone = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsZone.push(opt));
            this.updateFilterOptions('Zone__c', this.optionsZone);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Lease_Phases__FIELD })
    wiredLeasePhasesOptions({error, data}) {
        if (data) {
            this.optionsLeasePhases = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsLeasePhases.push(opt));
            this.updateFilterOptions('Lease_Phases__c', this.optionsLeasePhases);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Tower_Name__FIELD })
    wiredTowerNameOptions({error, data}) {
        if (data) {
            this.optionsTowerName = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsTowerName.push(opt));
            this.updateFilterOptions('Tower_Name__c', this.optionsTowerName);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Building_Type__FIELD })
    wiredBuildingTypeOptions({error, data}) {
        if (data) {
            this.optionsBuildingType = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsBuildingType.push(opt));
            this.updateFilterOptions('Building_Type__c', this.optionsBuildingType);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Status__FIELD })
    wiredStatusOptions({error, data}) {
        if (data) {
            this.optionsStatus = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsStatus.push(opt));
            this.updateFilterOptions('Status__c', this.optionsStatus);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Level__FIELD })
    wiredLevelOptions({error, data}) {
        if (data) {
            this.optionsLevel = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsLevel.push(opt));
            this.updateFilterOptions('Level__c', this.optionsLevel);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Unit_No__FIELD })
    wiredUnitNoOptions({error, data}) {
        if (data) {
            this.optionsUnitNo = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsUnitNo.push(opt));
            this.updateFilterOptions('Unit_No__c', this.optionsUnitNo);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: View__FIELD })
    wiredViewOptions({error, data}) {
        if (data) {
            this.optionsView = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsView.push(opt));
            this.updateFilterOptions('View__c', this.optionsView);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Apartment_Type__FIELD })
    wiredApartmentTypeOptions({error, data}) {
        if (data) {
            this.optionsApartmentType = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsApartmentType.push(opt));
            this.updateFilterOptions('Apartment_Type__c', this.optionsApartmentType);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Unit_Type__FIELD })
    wiredUnitTypeOptions({error, data}) {
        if (data) {
            this.optionsUnitType = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsUnitType.push(opt));
            this.updateFilterOptions('Unit_Type__c', this.optionsUnitType);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: Retail_Category__FIELD })
    wiredRetailCategoryOptions({error, data}) {
        if (data) {
            this.optionsRetailCategory = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsRetailCategory.push(opt));
            this.updateFilterOptions('Retail_Category__c', this.optionsRetailCategory);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: TypeOfActivity__FIELD })
    wiredTypeOfActivityOptions({error, data}) {
        if (data) {
            this.optionsTypeOfActivity = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsTypeOfActivity.push(opt));
            this.updateFilterOptions('Type_of_Activity__c', this.optionsTypeOfActivity);
            this.checkAndLoadData();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: LocationAndVisibility__FIELD })
    wiredLocationAndVisibilityOptions({error, data}) {
        if (data) {
            this.optionsLocationAndVisibility = [{ label: '--None--', value: "" }];
            data.values.forEach(opt => this.optionsLocationAndVisibility.push(opt));
            this.updateFilterOptions('LocationAndVisibility__c', this.optionsLocationAndVisibility);
            this.checkAndLoadData();
        } else if (error) {
            console.log('LocationAndVisibility field not available:', error);
        }
    }

    dataLoadAttempted = false;
    
    checkAndLoadData() {
        // Only load data once after at least one picklist has loaded and config is initialized
        if (this.configInitialized && !this.dataLoadAttempted) {
            this.dataLoadAttempted = true;
            this.getData();
        }
    }

    updateFilterOptions(fieldApiName, options) {
        if (!this.filterOptions) {
            this.filterOptions = {};
        }
        this.filterOptions[fieldApiName] = options;
    }

    getFilterOptions(fieldApiName) {
        const optionMap = {
            'Zone__c': this.optionsZone,
            'Lease_Phases__c': this.optionsLeasePhases,
            'Tower_Name__c': this.optionsTowerName,
            'Building_Type__c': this.optionsBuildingType,
            'Status__c': this.optionsStatus,
            'Level__c': this.optionsLevel,
            'Unit_No__c': this.optionsUnitNo,
            'View__c': this.optionsView,
            'Apartment_Type__c': this.optionsApartmentType,
            'Unit_Type__c': this.optionsUnitType,
            'Retail_Category__c': this.optionsRetailCategory,
            'Type_of_Activity__c': this.optionsTypeOfActivity,
            'LocationAndVisibility__c': this.optionsLocationAndVisibility
        };
        return optionMap[fieldApiName] || [];
    }

    getFilterValue(fieldApiName) {
        const valueMap = {
            'Zone__c': this.valueZone,
            'Lease_Phases__c': this.valueLeasePhases,
            'Tower_Name__c': this.valueTowerName,
            'Building_Type__c': this.valueBuildingType,
            'Status__c': this.valueStatus,
            'Level__c': this.valueLevel,
            'Unit_No__c': this.valueUnitNo,
            'View__c': this.valueView,
            'Apartment_Type__c': this.valueApartmentType,
            'Unit_Type__c': this.valueUnitType,
            'Retail_Category__c': this.valueRetailCategory,
            'Type_of_Activity__c': this.valueTypeOfActivity,
            'LocationAndVisibility__c': this.valueLocationAndVisibility
        };
        return valueMap[fieldApiName] || '';
    }

    handleFilterChange(event) {
        const fieldName = event.currentTarget.dataset.field;
        const value = event.detail.value;
        
        // Update the appropriate value property
        switch(fieldName) {
            case 'Zone__c': this.valueZone = value; break;
            case 'Lease_Phases__c': this.valueLeasePhases = value; break;
            case 'Tower_Name__c': this.valueTowerName = value; break;
            case 'Building_Type__c': this.valueBuildingType = value; break;
            case 'Status__c': this.valueStatus = value; break;
            case 'Level__c': this.valueLevel = value; break;
            case 'Unit_No__c': this.valueUnitNo = value; break;
            case 'View__c': this.valueView = value; break;
            case 'Apartment_Type__c': this.valueApartmentType = value; break;
            case 'Unit_Type__c': this.valueUnitType = value; break;
            case 'Retail_Category__c': this.valueRetailCategory = value; break;
            case 'Type_of_Activity__c': this.valueTypeOfActivity = value; break;
            case 'LocationAndVisibility__c': this.valueLocationAndVisibility = value; break;
        }
        
        this.getData();
    }

    handleSuccess() {
        const evt = new ShowToastEvent({
            title: "Success!",
            message: "The record has been successfully saved.",
            variant: "success",
        });
        this.dispatchEvent(evt);
        this.getData();
        this.isModalOpen = false;
    }

    updatePage() {
        this.getData();
    }
       
    handleError(event) {
        console.error('Form error:', event.detail);
        const evt = new ShowToastEvent({
            title: "Error!",
            message: event.detail?.message || "An error occurred while attempting to save the record.",
            variant: "error",
        });
        this.dispatchEvent(evt);
        this.isModalOpen = false;
    }

    handleCancel() {
        this.isModalOpen = false;
    }

    getData() {
        if (!this.recordId) {
            console.log('No recordId available yet');
            return;
        }

        // Build filter parameters object using the actual value properties
        const filterParams = {
            zone: this.valueZone || '',
            Lease_Phases: this.valueLeasePhases || '',
            Tower_Name: this.valueTowerName || '',
            Building_Type: this.valueBuildingType || '',
            Status: this.valueStatus || '',
            Level: this.valueLevel || '',
            Apartment_Type: this.valueApartmentType || '',
            Unit_No: this.valueUnitNo || '',
            View: this.valueView || '',
            Unit_Type: this.valueUnitType || '',
            Retail_Category: this.valueRetailCategory || '',
            Type_of_Activity: this.valueTypeOfActivity || '',
            LocationAndVisibility: this.valueLocationAndVisibility || ''
        };

        console.log('Fetching data with filters:', filterParams);

        getAllBuildings({ 
            dealRecordId: this.recordId,
            ...filterParams
        })
        .then(result => {
            console.log('Fetched Buildings Data count:', result?.length);
            if (result && result.length > 0) {
                console.log('Sample record:', JSON.stringify(result[0]));
            }
            this.records = this.processRecords(result);
            for(let item of this.records){
                item.selected = this.booleItem;
            }
        })
        .catch(error => {
            this.error = error;
            this.records = undefined;
            console.error('getData error (buildings):', JSON.stringify(error));
        });

        getRelatedDealBuilding({ dealRecordId: this.recordId })
        .then(result => {
            console.log('Fetched Deal Records count:', result?.length);
            if (result && result.length > 0) {
                console.log('Sample deal record:', JSON.stringify(result[0]));
            }
            this.dealRecords = this.processRecords(result);
        })
        .catch(error => {
            this.error = error;
            this.dealRecords = undefined;
            console.error('getData error (deal buildings):', JSON.stringify(error));
        });
    }

    // Process records to add column values for template access
    processRecords(records) {
        if (!records) return records;
        const allColumns = [...(this.dealColumns || []), ...(this.unitColumns || [])];
        
        return records.map(record => {
            const processed = { ...record };
            // Add column values as direct properties for template access
            allColumns.forEach(col => {
                const fieldValue = record[col.fieldApiName];
                // Create a property name that's safe for template access
                processed[`col_${col.fieldApiName}`] = fieldValue;
            });
            return processed;
        });
    }

    // Getter to process deal records with column values in an array
    get processedDealRecords() {
        if (!this.dealRecords || !this.dealColumns) return this.dealRecords || [];
        return this.dealRecords.map(record => {
            const processed = { ...record };
            // Create an array of cell values indexed by column position
            processed.cellValues = this.dealColumns.map(col => record[col.fieldApiName]);
            return processed;
        });
    }

    // Getter to process unit records with column values in an array
    get processedRecords() {
        if (!this.records || !this.unitColumns) return this.records || [];
        return this.records.map(record => {
            const processed = { ...record };
            // Create an array of cell values indexed by column position
            processed.cellValues = this.unitColumns.map(col => record[col.fieldApiName]);
            return processed;
        });
    }

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

    handleChange(event) {
        if(event.target.checked == true){
            for(let item of this.records){
                this.booleItem = true;
                item.selected = this.booleItem;
            }
        } else {
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
        } else {
            for(let item of this.records){
                if(item.Id == event.target.dataset.id){
                    item.selected = false;
                }
            }
        }
    }

    getAllId(event) {
        const checked = Array.from(
            this.template.querySelectorAll('lightning-input')
        )
        .filter(element => element.checked)
        .map(element => element.dataset.id);

        let errormessageitem = '';
        for(let item of this.records){
            if(item.selected && item.Status__c != 'Available Units'){
                errormessageitem = errormessageitem + item.Status__c;
            }
        }

        let selection = checked.join(', ');
        if(errormessageitem != ''){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error adding Units',
                    message: 'Please select available unit!',
                    variant: 'error'
                })
            );
        } else {
            createJunctionObject({
                dealRecordId: this.recordId,
                stringBuildingsIds: selection
            })
            .then(result => {
                this.showSuccessEvent();
                this.getData();
                eval("$A.get('e.force:refreshView').fire();");
            })
            .catch(error => {
                this.error = error;
                console.error('create junction error:', JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating junction',
                        message: error.body?.message || 'An error occurred',
                        variant: 'error'
                    })
                );
            });
        }
    }
    
    showSuccessEvent() {
        const event = new ShowToastEvent({
            title: 'Success!',
            variant: 'success',
            message: 'Units were added successfully.',
        });
        this.dispatchEvent(event);
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
        return this.getData();
    }

    deleteRecordModal(event) {
        this.recordDeleteId = event.target.dataset.id;
        this.isModalOpen2 = true;
    }

    closeModal2() {
        this.isModalOpen2 = false;
    }

    submitDetails2() {
        if (!this.recordDeleteId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No record selected for deletion',
                    variant: 'error'
                })
            );
            this.isModalOpen2 = false;
            return;
        }

        deleteRecord(this.recordDeleteId)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Record deleted successfully',
                    variant: 'success'
                })
            );
            this.recordDeleteId = null;
            this.getData();
        })
        .catch(error => {
            console.error('Delete error:', JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting record',
                    message: error.body?.message || 'An error occurred while deleting the record',
                    variant: 'error'
                })
            );
        });
        this.isModalOpen2 = false;
    }

    // Helper method to get field value from record
    getFieldValue(record, fieldApiName) {
        if (!record || !fieldApiName) return '';
        // Handle nested fields (e.g., Building__r.Name)
        const parts = fieldApiName.split('.');
        let value = record;
        for (const part of parts) {
            if (value && typeof value === 'object') {
                value = value[part];
            } else {
                return '';
            }
        }
        return value || '';
    }

    // Helper to get cell value for display
    getCellValue(record, column) {
        if (!record || !column) return '';
        return record[column.fieldApiName] || '';
    }

    // Helper to check if column is currency type
    isCurrencyColumn(column) {
        return column && column.type === 'currency';
    }

    // Helper to check if column is number type
    isNumberColumn(column) {
        return column && column.type === 'number';
    }

    // Helper to check if column is text type
    isTextColumn(column) {
        return column && (column.type === 'text' || !column.type);
    }

    // Computed property to get filter fields with their options and values
    get filterFieldsWithData() {
        if (!this.filterFields || this.filterFields.length === 0) {
            return [];
        }
        
        return this.filterFields.map(field => {
            return {
                ...field,
                options: this.getFilterOptions(field.fieldApiName),
                value: this.getFilterValue(field.fieldApiName)
            };
        });
    }

    // Helper to get processed columns with safe labels
    get processedDealColumns() {
        if (!this.dealColumns) return [];
        return this.dealColumns.map((col, index) => {
            const processed = {
                ...col,
                index: index
            };
            // Set boolean flags for template conditions
            processed.isCurrency = (col.type === 'currency');
            processed.isNumber = (col.type === 'number');
            processed.isText = (col.type === 'text' || !col.type);
            return processed;
        });
    }

    get processedUnitColumns() {
        if (!this.unitColumns) return [];
        return this.unitColumns.map((col, index) => {
            const processed = {
                ...col,
                index: index
            };
            // Set boolean flags for template conditions
            processed.isCurrency = (col.type === 'currency');
            processed.isNumber = (col.type === 'number');
            processed.isText = (col.type === 'text' || !col.type);
            return processed;
        });
    }

    // Helper to get cell value - this will be called from template
    getCellValueByIndex(record, index) {
        if (!record || !record.cellValues || index === undefined) return '';
        return record.cellValues[index] || '';
    }

    renderedCallback() {
        // Set innerHTML for column headers to support HTML like <br>
        this.setColumnHeaderHTML();
    }

    setColumnHeaderHTML() {
        // Deal columns headers
        const dealHeaders = this.template.querySelectorAll('table:first-of-type thead th[data-column-index]');
        if (dealHeaders && this.dealColumns) {
            dealHeaders.forEach(header => {
                const index = parseInt(header.getAttribute('data-column-index'));
                const col = this.dealColumns[index];
                if (col && col.label) {
                    header.innerHTML = col.label;
                }
            });
        }

        // Unit columns headers (skip checkbox column)
        const unitHeaders = this.template.querySelectorAll('table:last-of-type thead th[data-column-index]');
        if (unitHeaders && this.unitColumns) {
            unitHeaders.forEach(header => {
                const index = parseInt(header.getAttribute('data-column-index'));
                const col = this.unitColumns[index];
                if (col && col.label) {
                    header.innerHTML = col.label;
                }
            });
        }
    }
}