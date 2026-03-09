public class OpportunityQueryBuilder {
    private String opportunityId;
    private List<String> opportunityFields;
    private List<String> dealBuildingFields;
    private List<String> paymentScheduleFields;
    private List<String> otherChargeFields;

    public OpportunityQueryBuilder withDealBuildingFields(List<String> fields) {
        this.dealBuildingFields = fields;
        return this;
    }
    
    public OpportunityQueryBuilder withOpportunityId(String opportunityId) {
        this.opportunityId = opportunityId;
        return this;
    }
    
    public OpportunityQueryBuilder withOpportunityFields(List<String> fields) {
        this.opportunityFields = fields;
        return this;
    }
    
    public OpportunityQueryBuilder withPaymentScheduleFields(List<String> fields) {
        this.paymentScheduleFields = fields;
        return this;
    }
    
    public OpportunityQueryBuilder withOtherChargeFields(List<String> fields) {
        this.otherChargeFields = fields;
        return this;
    }
    
    public String build() {
        Set<String> fieldsSet = new Set<String>(opportunityFields);
        fieldsSet.add('Id');
        
        String query = 'SELECT ' + String.join(new List<String>(fieldsSet), ', ');
        
        if (paymentScheduleFields != null && !paymentScheduleFields.isEmpty()) {
            query += ', (SELECT ' + String.join(paymentScheduleFields, ', ') + 
                     ' FROM PaymentSchedule__r ORDER BY Scheduled_Payment_Date__c)';
        }
        
        if (otherChargeFields != null && !otherChargeFields.isEmpty()) {
            query += ', (SELECT ' + String.join(otherChargeFields, ', ') + 
                     ' FROM Other_Charges__r ORDER BY Year__c, Category__c)';
        }
        
        if (dealBuildingFields != null && !dealBuildingFields.isEmpty()) {
            query += ', (SELECT ' + String.join(dealBuildingFields, ', ') + 
                     ' FROM Deal_Buildings__r ORDER BY Name)';
        }
        
        query += ' FROM Opportunity WHERE Id = \'' + this.opportunityId + '\' LIMIT 1';
        
        return query;
    }
}