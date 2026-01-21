global class UpdateBuildingStatus Implements Schedulable{
    global void execute(SchedulableContext sc){
        setToStatusBuilding();
    }
    
    public void setToStatusBuilding(){
        List<Opportunity> oppLst = [SELECT Id FROM Opportunity WHERE End_Date__c =: Date.today()];
        Set<Id> lstOppId = new Set<Id>();
        for(Opportunity opp :oppLst){
            System.debug(opp);
            lstOppId.add(opp.Id);
        }
        
        List<Deal_Building__c> dbList = [SELECT Id, Building__c FROM Deal_Building__c WHERE Deal__c IN:lstOppId];
        Set<Id> buildingsId = new Set<Id>();
        for(Deal_Building__c dbItem : dbList){
            buildingsId.add(dbItem.Building__c);
        }
        
        List<Building__c> lstBuildings = [SELECT Id, Status__c FROM Building__c WHERE Id IN:buildingsId];
        List<Building__c> lstBuildingsForUpdate = New List<Building__c>();
        for(Building__c bItem : lstBuildings){
            if(bItem.Status__c != 'Available Units'){
            	bItem.Status__c = 'Available Units';
                lstBuildingsForUpdate.add(bItem);
            }
             
        }
        update lstBuildingsForUpdate;
    }
}