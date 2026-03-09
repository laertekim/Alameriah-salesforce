public class DealBuildingRepository {
    
    public Map<Id, Deal_Building__c> getDealBuildingsAllFields(Set<Id> dealBuildingIds) {
        List<String> fieldNames = new List<String>();
        
        for (Schema.SObjectField field : 
             Schema.getGlobalDescribe()
                   .get('Deal_Building__c')
                   .getDescribe()
                   .fields.getMap()
                   .values()) {
            
            fieldNames.add(field.getDescribe().getName());
        }
        
        String query = 'SELECT ' + String.join(fieldNames, ',') +
                       ' FROM Deal_Building__c WHERE Id IN :dealBuildingIds';
        
        return new Map<Id, Deal_Building__c>(
            (List<Deal_Building__c>) Database.query(query)
        );
    }
}