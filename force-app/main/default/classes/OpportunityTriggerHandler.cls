public class OpportunityTriggerHandler {
	public static void afterUpdate(List<Opportunity> newItems, Map<Id,Opportunity>oldMap) {
        populateOwnerField(newItems, oldMap);
    }
    
    private static void populateOwnerField(List<Opportunity> newItems, Map<Id,Opportunity>oldMap) {
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
        Map<String, String> mapDelBuildings = new Map<String, String>();
        for(Opportunity opp :newItems){
            if(opp.StageName != oldMap.get(opp.Id).StageName){
            	oppMap.put(opp.Id, opp);
            }
            System.debug('opp.Id '+opp.Id);
        }
        if(oppMap.keySet().size() > 0){
            for(Deal_Building__c db :[SELECT Id, Deal__c, Building__c FROM Deal_Building__c WHERE Deal__c IN: oppMap.keySet()]){
                mapDelBuildings.put(db.Building__c, db.Deal__c);
                System.debug('db.Id '+db.Id);
            }
            
            List<Building__c> lstBDoupdate = new List<Building__c>();
            
            for(Building__c bd :[SELECT Id, Status__c FROM Building__c WHERE Id IN :mapDelBuildings.keySet()]){
                if(oppMap.get(mapDelBuildings.get(bd.Id)).StageName != 'Closed Lost'){
                    System.debug('bd.Status__c '+bd.Status__c+' oppMap.get(mapDelBuildings.get(bd.Id)).StageName '+oppMap.get(mapDelBuildings.get(bd.Id)).StageName);
                    bd.Status__c = oppMap.get(mapDelBuildings.get(bd.Id)).StageName;
                    System.debug('bd.Id '+bd.Id);
                }
                if(oppMap.get(mapDelBuildings.get(bd.Id)).StageName == 'Closed Lost'){
                    bd.Status__c = 'Available Units';
                }
                    lstBDoupdate.add(bd); 	   
            }
            
            update lstBDoupdate;
    	}
    }
}