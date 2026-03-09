public class OpportunityReportController {
    private Opportunity opportunity;
    private IFieldConfigurationProvider configProvider;
    private FieldDataRetriever dataRetriever;
    
    private List<FieldDescriptor> opportunityFieldDescriptors;
    private List<RecordDescriptor> paymentScheduleRecordDescriptors;
    private List<RecordDescriptor> otherChargeRecordDescriptors;
    private List<Deal_Building__c> dealBuildingList;
    private List<RecordDescriptor> dealBuildingRecordDescriptors;
    
    public OpportunityReportController(ApexPages.StandardController stdController) {
        this.opportunity = (Opportunity) stdController.getRecord();
        this.configProvider = getConfigurationProvider();
        this.dataRetriever = new FieldDataRetriever();
        
        loadOpportunityData();
    }
    
    @TestVisible
    private IFieldConfigurationProvider getConfigurationProvider() {
     
            return new DefaultFieldConfigurationProvider();
     
    }
    
    private void loadOpportunityData() {
        List<String> oppFields = configProvider.getOpportunityFields();
        List<String> paymentFields = configProvider.getPaymentScheduleFields();
        List<String> chargeFields = configProvider.getOtherChargeFields();
        List<String> dealBuildingFields = configProvider.getDealBuildingFields();
        
        String query = new OpportunityQueryBuilder()
        .withOpportunityId(opportunity.Id)
        .withOpportunityFields(oppFields)
        .withPaymentScheduleFields(paymentFields)
        .withOtherChargeFields(chargeFields)
        .withDealBuildingFields(dealBuildingFields)
        .build();
        
        Opportunity loadedOpp = Database.query(query);
        
        this.dealBuildingList = new List<Deal_Building__c>();
        List<SObject> dbs = loadedOpp.getSObjects('Deal_Buildings__r');
        if (dbs != null) {
            for (SObject s : dbs) {
                this.dealBuildingList.add((Deal_Building__c) s);
            }
        }
        this.opportunityFieldDescriptors = dataRetriever.retrieveFields(
            loadedOpp, 
            oppFields, 
            'Opportunity'
        );
        
        List<SObject> paymentSchedules = new List<SObject>();
        if (!paymentFields.isEmpty()) {
            List<SObject> schedules = loadedOpp.getSObjects('PaymentSchedule__r');
            if (schedules != null) {
                paymentSchedules = schedules;
            }
        }
        System.debug('@@ Payment Schedules: ' + paymentSchedules);

        this.paymentScheduleRecordDescriptors = dataRetriever.retrieveRecords(
            paymentSchedules,
            paymentFields,
            'Payment_Schedule__c'
        );
        
        System.debug('@@ Payment Schedule Record Descriptors: ' + paymentScheduleRecordDescriptors);
        List<SObject> otherCharges = new List<SObject>();
        if (!chargeFields.isEmpty()) {
            List<SObject> charges = loadedOpp.getSObjects('Other_Charges__r');
            if (charges != null) {
                otherCharges = charges;
            }
        }
        
        System.debug('@@ Other Charges: ' + otherCharges);
        this.otherChargeRecordDescriptors = dataRetriever.retrieveRecords(
            otherCharges,
            chargeFields,
            'Other_Charges__c'
        );

        System.debug('@@ Other Charge Record Descriptors: ' + otherChargeRecordDescriptors);

        System.debug('dns Deal Building Fields: ' + dealBuildingFields);
        List<SObject> dealBuildings = new List<SObject>();
        if (!dealBuildingFields.isEmpty()) {
            List<SObject> buildings = loadedOpp.getSObjects('Deal_Buildings__r');
            if (buildings != null) {
                dealBuildings = buildings;
            }
        }
        this.dealBuildingRecordDescriptors = dataRetriever.retrieveRecords(
            dealBuildings,
            dealBuildingFields,
            'Deal_Building__c'
        );
    }
    
    public List<FieldDescriptor> getOpportunityFields() {
        return this.opportunityFieldDescriptors;
    }
    
    public List<FieldDescriptor> opportunityFields {
        get { return getOpportunityFields(); }
    }
    
    public List<FieldDescriptor> getPaymentScheduleFields() {
        if (this.paymentScheduleRecordDescriptors.isEmpty()) {
            return new List<FieldDescriptor>();
        }
        return this.paymentScheduleRecordDescriptors[0].getFields();
    }
    
    public List<FieldDescriptor> paymentScheduleFields {
        get { return getPaymentScheduleFields(); }
    }
    
    public List<RecordDescriptor> getPaymentScheduleRecords() {
        return this.paymentScheduleRecordDescriptors;
    }
    
    public List<RecordDescriptor> paymentScheduleRecords {
        get { return getPaymentScheduleRecords(); }
    }
    
    public Boolean getHasPaymentSchedules() {
        return !this.paymentScheduleRecordDescriptors.isEmpty();
    }
    
    public Boolean hasPaymentSchedules {
        get { return getHasPaymentSchedules(); }
    }
    
    public List<FieldDescriptor> getOtherChargeFields() {
        if (this.otherChargeRecordDescriptors.isEmpty()) {
            return new List<FieldDescriptor>();
        }
        return this.otherChargeRecordDescriptors[0].getFields();
    }
    
    public List<FieldDescriptor> otherChargeFields {
        get { return getOtherChargeFields(); }
    }
    
    public List<RecordDescriptor> getOtherChargeRecords() {
        return this.otherChargeRecordDescriptors;
    }
    
    public List<RecordDescriptor> otherChargeRecords {
        get { return getOtherChargeRecords(); }
    }
    
    public Boolean getHasOtherCharges() {
        return !this.otherChargeRecordDescriptors.isEmpty();
    }
    
    public Boolean hasOtherCharges {
        get { return getHasOtherCharges(); }
    }
    
    public List<Deal_Building__c> dealBuildings {
    	get { return this.dealBuildingList; }
    }
    
    public Boolean hasDealBuildings {
        get { return !this.dealBuildingList.isEmpty(); }
    }

    public List<FieldDescriptor> getDealBuildingFields() {
        if (this.dealBuildingRecordDescriptors.isEmpty()) {
            return new List<FieldDescriptor>();
        }
        return this.dealBuildingRecordDescriptors[0].getFields();
    }
    
    public List<FieldDescriptor> dealBuildingFields {
        get { return getDealBuildingFields(); }
    }
    
    public List<RecordDescriptor> getDealBuildingRecords() {
        return this.dealBuildingRecordDescriptors;
    }
    
    public List<RecordDescriptor> dealBuildingRecords {
        get { return getDealBuildingRecords(); }
    }

    public Boolean getHasDealBuildings() {
        return !this.dealBuildingRecordDescriptors.isEmpty();
    }
    
   
}