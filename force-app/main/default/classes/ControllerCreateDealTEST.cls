@istest
public class ControllerCreateDealTEST {
	testmethod static void saverecord(){
      Center__c newCentr = new Center__c();
      newCentr.Name = 'TestcenterOffices';
      insert newCentr;
      Building__c build = new Building__c();
      build.Name = 'TEST';
      insert build;  
      ControllerCreateDeal.getBulding(build.Id);
      Account acc = new Account();
      acc.Name = 'testAcc';
      insert acc;
        
      ControllerCreateDeal.createDeal(String.valueOf(build.Id),'TEST',String.valueOf(Date.today()),'Offered','Offices',String.valueOf(newCentr.Id),String.valueOf(acc.Id));
   }
}