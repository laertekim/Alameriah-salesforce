@istest
public class UpdateBuildingStatusTEST {
    testmethod static void testscheduleUpdateBuildings(){
        
    	Opportunity opp = new Opportunity();
        opp.End_Date__c = Date.today();
        opp.Name = 'Test';
        opp.StageName = 'Offered';
        opp.CloseDate = Date.today();
        opp.Amount = 1000;
        opp.Contract_Start_Date__c  = date.today().addYears(-2);
        opp.Term_of_Lease_Years__c  = 1;
        opp.Total_Annual_Rent_SR_Annum__c = 2000;
        insert opp;
        
        Building__c build = new Building__c();
        build.Name = 'Test';
        
        insert build;
        
        Deal_Building__c dealB = new Deal_Building__c();
        dealB.Deal__c = opp.Id;
        dealB.Building__c = build.Id;
        
        insert dealB;
        dealB.Total_Selling_Price_SAR__c = 1000;
        update dealB;
        
        DealJunkTableController.getRelatedDealBuilding(opp.Id);
        DealJunkTableController.createJunctionObject(opp.Id, build.Id);
        ControllerCreateDeal.getBulding(build.Id);
        ControllerCreateDeal.createDeal(build.Id, 'Retail Name', String.valueOf(Date.today()), 'Offered', 'Retail', null, null);
            
        UpdateBuildingStatus cvSLS = new UpdateBuildingStatus();
        String sch = '0 0 23 * * ?';
        Id jobId = System.schedule('UpdateBuildingStatus', sch, cvSLS);
        delete dealB;
        
        //ContractDateLostClass cvSLS1 = new ContractDateLostClass();
        //String sch1 = '0 0 23 * * ?';
        //Id jobId1 = System.schedule('ContractDateLostClass', sch1, cvSLS1);
        
        opp.StageName = 'Closed Lost';
        update opp;
    }
}