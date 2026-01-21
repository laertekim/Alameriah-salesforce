public class ContractDateLostClass implements Schedulable {
	public void execute(SchedulableContext ctx) {
        List<Opportunity> opptys = [SELECT Id, Name, OwnerId, CloseDate, Contract_End_Date__c
            FROM Opportunity
            WHERE Contract_End_Date__c < TODAY];
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
        Map<String, String> mapDelBuildings = new Map<String, String>();
        for(Opportunity opp :opptys){
        	System.debug('opptys '+opp.Name+' ---- '+opp.Contract_End_Date__c+' ------ '+Date.today());
            oppMap.put(opp.Id, opp);
        }
        
        if(oppMap.keySet().size() > 0){
            for(Deal_Building__c db :[SELECT Id, Deal__c, Building__c FROM Deal_Building__c WHERE Deal__c IN: oppMap.keySet()]){
                mapDelBuildings.put(db.Building__c, db.Deal__c);
                System.debug('db.Id '+db.Id);
            }
            
            List<Building__c> lstBDoupdate = new List<Building__c>();
            
            for(Building__c bd :[SELECT Id, Status__c FROM Building__c WHERE Id IN :mapDelBuildings.keySet()]){
                    bd.Status__c = 'Available Units';
                    lstBDoupdate.add(bd); 	   
            }
            
            update lstBDoupdate;
    	}
        
    }
}