public class BuildingRepository {
    
    public Map<Id, Building__c> getBuildingsWithPricing(Set<Id> buildingIds) {
        return new Map<Id, Building__c>([
            SELECT Id,
                   Gross_Leasable_Amount_SAR__c,
                   Total_Selling_Price_SAR__c,
                   Client_Asking_Price_SAR__c,
                   Asking_Annual_Rent__c
            FROM Building__c 
            WHERE Id IN :buildingIds
        ]);
    }

    public Map<Id, Building__c> getAllFields(Set<Id> buildingIds) {
        String query = 'SELECT ';
        for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Building__c').getDescribe().fields.getMap().values()) {
            query += field.getDescribe().getName() + ',';
        }
        //remove the last comma
        query = query.removeEnd(',');
        query += ' FROM Building__c WHERE Id IN :buildingIds';
        return new Map<Id, Building__c>((List<Building__c>)Database.query(query));
    }
}