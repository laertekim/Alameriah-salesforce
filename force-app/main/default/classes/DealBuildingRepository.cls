public class DealBuildingRepository {
    
    public Map<Id, Deal_Building__c> getDealBuildingsAllFields(Set<Id> dealBuildingIds) {
        String query = 'SELECT Id,';
        for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Deal_Building__c').getDescribe().fields.getMap().values()) {
            query += field.getDescribe().getName() + ',';
        }
        query += ' FROM Deal_Building__c WHERE Id IN :dealBuildingIds';
        return new Map<Id, Deal_Building__c>((List<Deal_Building__c>)Database.query(query));
    }

   
}