public with sharing class DealJunkTableController {

    public class ObjectDTO {
        @AuraEnabled public Map<String, String> fieldAndValue;
        
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
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Building__c WHERE RecordType.name = \'Residential Property\'';
        for(String field : objDTO.fieldAndValue.keySet()){
            if(objDTO.fieldAndValue.get(field) != null && objDTO.fieldAndValue.get(field) != ''){
                query += ' AND ' + field + ' = \'' + objDTO.fieldAndValue.get(field) + '\'';
            }
        }

        
        return Database.query(query);
    }

    @AuraEnabled
    public static List<Building__c> getAllBuildings(String dealRecordId, 
                                                    String zone, 
                                                    String Lease_Phases, 
                                                    String Tower_Name, 
                                                    String Building_Type, 
                                                    String Status, 
                                                    String Level,
                                                    String Apartment_Type, 
                                                    String Unit_No, 
                                                    String View, 
                                                    String Unit_Type,
                                                    String Retail_Category,
                                                    String Type_of_Activity) {
        Opportunity opp = [SELECt Id, Site__c, RecordType.name FROM Opportunity WHERE Id =:dealRecordId];                                                
        System.debug('Zone '+opp.Site__c);
        String central = opp.RecordType.name;
        String siteDeal = opp.Site__c;
        if(central != null){
            String queryFeature = 'SELECT Id, '
                                + 'Name, '
                                + 'Status__c, '
                                + 'Zone__c, '
                                + 'Tower_Name__c, '
                                + 'Lease_Phases__c, '
                                + 'Level__c, '
                                + 'Apartment_Type__c, '
                                + 'Min_Weighted__c, '
                                + 'Min_Weighted_Rate__c, '
                                + 'Minimum_Annual_Rent__c, '
                                + 'Client_Min_Price_SAR__c, '
                                + 'Ask_Weighted__c, '
                                + 'Ask_Weighted_Rate__c, '
                                + 'Client_Asking_Price_SAR__c, '
                                + 'Center_Name__c, '
                                + 'Building_Type__c, '
                                + 'Unit_No__c, '
                                + 'View__c, '
                                + 'Total_Unit_Area_Sqm__c, '
                                + 'Office_Area_Sqm__c, '
                                + 'Service_Area_Sqm__c, '
                                + 'Passage_Area_Sqm__c, '
                                + 'wc_Toilets_Area_Sqm__c, '
                                + 'Total_Leasable_Area_Sqm__c, '
                                + 'Terrace_Area_Sqm__c, '
                                + 'Leasing_Rate_Sqm_SAR__c, '
                                + 'Price_Sqm_SAR_Services__c, '
                                + 'Price_Sqm_SAR_Terraces__c, '
                                //+ 'Client_Prices_NSA1__c, '
                                + 'Total_Prices_Services_Areas__c, '
                                + 'Total_Prices_Terraces_Areas__c, '
                                + 'Gross_Leasable_Amount_SAR__c, '
                                + 'Unit_Area_Sqm_NSA__c, '
                                + 'Total_NSA__c, '
                                + 'Agent_Commission_8__c, '
                                + 'Edara_Commission_2__c, '
                                + 'Lobby_Area_Sqm__c, '
                                + 'Total_Prices_Lobby_Areas__c, '
                                + 'Price_Sqm_SAR_Lobby__c, '
                                + 'Total_Selling_Price_SAR__c, Unit_Area_Sqm__c, Asking_Price__c, Asking_Annual_Rent__c, Retail_Category__c, Type_of_Activity__c, '
                                + 'Unit_Type__c '
                                + 'FROM Building__c WHERE Name != NULL'
                                + (central != '' ? ' AND RecordType.name = \'' + central + '\'' : '')
                                + (siteDeal != '' ? ' AND Center_Name__c = \'' + siteDeal + '\'' : '')
        + (Lease_Phases != '' ? ' AND Lease_Phases__c = \'' + Lease_Phases + '\'' : '')
        + (Tower_Name != '' ? ' AND Tower_Name__c = \'' + Tower_Name + '\'' : '')
        + (Building_Type != '' ? ' AND Building_Type__c = \'' + Building_Type + '\'' : '')
        + (Unit_No != '' ? ' AND Unit_No__c = \'' + Unit_No + '\'' : '')        
        + (Status != '' ? ' AND Status__c = \'' + Status + '\'' : '')
        + (Level != '' ? ' AND Level__c = \'' + Level + '\'' : '')
        + (Apartment_Type != '' ? ' AND Apartment_Type__c = \'' + Apartment_Type + '\'' : '')
        + (Unit_Type != '' ? ' AND Unit_Type__c = \'' + Unit_Type + '\'' : '')
        + (Retail_Category != '' ? ' AND Retail_Category__c = \'' + Retail_Category + '\'' : '')
        + (Type_of_Activity != '' ? ' AND Type_of_Activity__c = \'' + Type_of_Activity + '\'' : '')
        + (View != '' ? ' AND View__c = \'' + View + '\'' : '')
        + (zone != '' ? ' AND Zone__c = \'' + zone + '\'' : '');
            System.debug('TEST');
            return (List<Building__c>)Database.query(queryFeature); 
        }else{
            return  new List<Building__c> ();
        }
          
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