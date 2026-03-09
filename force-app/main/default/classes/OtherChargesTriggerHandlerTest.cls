@IsTest
private class OtherChargesTriggerHandlerTest {

    private static Opportunity createOpportunity(Decimal totalSellingPrice) {
        Opportunity opp = new Opportunity(
            Name = 'Opp OC ' + String.valueOf(DateTime.now().getTime()),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            TotalSellingPrice__c = totalSellingPrice
        );
        insert opp;
        return opp;
    }

    @IsTest
    static void afterInsert_shouldAddAmountToTotalSellingPrice() {
        Opportunity opp = createOpportunity(100);

        Test.startTest();
        insert new Other_Charges__c(
            Deal__c = opp.Id,
            Amount__c = 50
        );
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT TotalSellingPrice__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(150, updatedOpp.TotalSellingPrice__c);
    }

    @IsTest
    static void afterUpdate_shouldHandleAmountChange() {
        Opportunity opp = createOpportunity(100);

        Other_Charges__c charge = new Other_Charges__c(
            Deal__c = opp.Id,
            Amount__c = 40
        );
        insert charge;

        Test.startTest();
        charge.Amount__c = 70;
        update charge;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT TotalSellingPrice__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // Initial 100 + insert 40 + update difference (70-40)
        System.assertEquals(170, updatedOpp.TotalSellingPrice__c);
    }

    @IsTest
    static void afterDeleteAndUndelete_shouldAdjustTotalSellingPrice() {
        Opportunity opp = createOpportunity(500);

        Other_Charges__c charge = new Other_Charges__c(
            Deal__c = opp.Id,
            Amount__c = 60
        );
        insert charge;

        Test.startTest();
        delete charge;
        undelete charge;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT TotalSellingPrice__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals(560, updatedOpp.TotalSellingPrice__c);
    }
}
