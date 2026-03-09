public with sharing class DealJunkTableController {

    public class ObjectDTO {
        @AuraEnabled public Map<String, String> fieldAndValue;
        
    }

    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(Id recordId){
        return [SELECT Site__c, RecordType.Name FROM Opportunity WHERE Id = :recordId];
    }

    @AuraEnabled(cacheable=true)
    public static List<Field_Display_Config__mdt> getFieldConfig(String recordTypeName) {
        return [SELECT Field_API_Name__c, Column_Label__c, Display_Order__c
                FROM Field_Display_Config__mdt
                WHERE RecordType__c = :recordTypeName AND Is_Visible__c = true
                ORDER BY Display_Order__c ASC NULLS LAST];
    }

    @AuraEnabled
    public static List<Building__c> getAllBuildingsResidentialProperty(String objectDTO) {
        
        ObjectDTO objDTO = (ObjectDTO)JSON.deserialize(objectDTO, ObjectDTO.class);
        //query all fields from Building__c object using schema describe
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get('Building__c').getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        List<String> fields = new List<String>();
        for(Schema.SObjectField field : fieldMap.values()){
            fields.add(field.getDescribe().getName());
        }
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Building__c WHERE (RecordType.name = \'Residential Property\' OR RecordType.name = \'Residential\') ';
        for(String field : objDTO.fieldAndValue.keySet()){
            if(objDTO.fieldAndValue.get(field) != null && objDTO.fieldAndValue.get(field) != ''){
                if(field == 'Tower_No__c') {
                    query += ' AND ' + field + ' INCLUDES (\'' + objDTO.fieldAndValue.get(field) + '\')';
                } else {
                    query += ' AND ' + field + ' = \'' + objDTO.fieldAndValue.get(field) + '\'';
                }
            }
        }

        
        return Database.query(query);
    }

    @AuraEnabled
    public static List<Building__c> getAllBuildings(
        String dealRecordId,
        String zone,
        String leasePhases,
        String towerName,
        String buildingType,
        String status,
        String level,
        String apartmentType,
        String unitNo,
        String viewValue,
        String unitType,
        String retailCategory,
        String typeOfActivity
    ) {
        if (String.isBlank(dealRecordId)) {
            return new List<Building__c>();
        }
    
        List<Opportunity> oppList = [
            SELECT Id, Site__c, RecordType.Name
            FROM Opportunity
            WHERE Id = :dealRecordId
            LIMIT 1
        ];
    
        if (oppList.isEmpty()) {
            return new List<Building__c>();
        }
    
        Opportunity opp = oppList[0];
    
        // ✅ Extract to simple variables (fix for dynamic SOQL bind)
        String recordTypeName = (opp.RecordType != null) ? opp.RecordType.Name : null;
        String siteName = opp.Site__c;
    
        List<String> conditions = new List<String>();
        conditions.add('Name != NULL');
    
        if (!String.isBlank(recordTypeName)) {
            conditions.add('RecordType.Name = :recordTypeName');
        }
    
        if (!String.isBlank(siteName)) {
            conditions.add('Center_Name__c = :siteName');
        }
    
        if (!String.isBlank(leasePhases)) {
            conditions.add('Lease_Phases__c = :leasePhases');
        }
    
        if (!String.isBlank(towerName)) {
            conditions.add('Tower_Name__c = :towerName');
        }
    
        if (!String.isBlank(buildingType)) {
            conditions.add('Building_Type__c = :buildingType');
        }
    
        if (!String.isBlank(unitNo)) {
            conditions.add('Unit_No__c = :unitNo');
        }
    
        if (!String.isBlank(status)) {
            conditions.add('Status__c = :status');
        }
    
        if (!String.isBlank(level)) {
            conditions.add('Level__c = :level');
        }
    
        if (!String.isBlank(apartmentType)) {
            conditions.add('Apartment_Type__c = :apartmentType');
        }
    
        if (!String.isBlank(unitType)) {
            conditions.add('Unit_Type__c = :unitType');
        }
    
        if (!String.isBlank(retailCategory)) {
            conditions.add('Retail_Category__c = :retailCategory');
        }
    
        if (!String.isBlank(typeOfActivity)) {
            conditions.add('Type_of_Activity__c = :typeOfActivity');
        }
    
        if (!String.isBlank(viewValue)) {
            conditions.add('View__c = :viewValue');
        }
    
        if (!String.isBlank(zone)) {
            conditions.add('Zone__c = :zone');
        }
    
        Schema.DescribeSObjectResult describeResult = Building__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        List<String> selectFields = new List<String>(fieldMap.keySet());
        String query = 'SELECT ' + String.join(selectFields, ', ') + ' FROM Building__c';
    
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
    
        return Database.query(query);
    }
    
    @AuraEnabled
    public static List<Deal_Building__c> getRelatedDealBuilding(String dealRecordId) {

        //get all fields from Deal_Building__c object using schema describe
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get('Deal_Building__c').getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        List<String> fields = new List<String>();
        for(Schema.SObjectField field : fieldMap.values()){
            fields.add(field.getDescribe().getName());
        }
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Deal_Building__c WHERE Deal__c =: dealRecordId';
        System.debug('@@ query '+Database.query(query));
        return Database.query(query);
       
    } 

    @AuraEnabled
    public static void createJunctionObject(String dealRecordId, String stringBuildingsIds) {
        
        List<String> buildingsIds = new List<String>();
        if(stringBuildingsIds != ''){
            buildingsIds = stringBuildingsIds.split(', ');
        }
          
        List<Deal_Building__c> lstForCreated = new List<Deal_Building__c>();
        for(String str :buildingsIds){
            Deal_Building__c dbItem = new Deal_Building__c();
            dbItem.Building__c = str;
            dbItem.Deal__c = dealRecordId;
            lstForCreated.add(dbItem);
        }
        insert lstForCreated;
        
        List<Building__c> buildings = new List<Building__c>();
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :dealRecordId];
        if(buildingsIds.size() > 0){
            buildings = [SELECT Id, Status__c FROM Building__c WHERE Id IN:buildingsIds];
            for(Building__c itembd :buildings){
                if(itembd.Status__c != opp.StageName){
                    itembd.Status__c = opp.StageName;
                }
            }
        }
        update buildings;
       
    }
}