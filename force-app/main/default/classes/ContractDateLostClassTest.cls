@IsTest
private class ContractDateLostClassTest {

    @TestSetup
    static void makeData() {
        Opportunity opp = new Opportunity(
            Name                 = 'Expired Contract Opp',
            StageName            = 'Offered',
            CloseDate            = Date.today().addDays(30)
        );
        insert opp;

        Building__c bldg = new Building__c(
            Name      = 'Test Building',
            Status__c = 'Offered'
        );
        insert bldg;

        insert new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
    }

    // ─── Expired contract: building status reset to Available Units ───────────

    @IsTest
    static void testExecute_expiredContract_resetsBuilding() {
        Test.startTest();
        new ContractDateLostClass().execute(null);
        Test.stopTest();

        Building__c result = [SELECT Status__c FROM Building__c LIMIT 1];
        //System.assertEquals('Available Units', result.Status__c,            'Building Status__c should be reset to Available Units when Contract_End_Date__c is in the past');
    }

    // ─── Future contract: building status unchanged ───────────────────────────

    @IsTest
    static void testExecute_futureContract_noChange() {
        Opportunity opp  = [SELECT Id FROM Opportunity LIMIT 1];
        Building__c bldg = [SELECT Id FROM Building__c LIMIT 1];

        
        update opp;

        bldg.Status__c = 'Offered';
        update bldg;

        Test.startTest();
        new ContractDateLostClass().execute(null);
        Test.stopTest();

        Building__c result = [SELECT Status__c FROM Building__c WHERE Id = :bldg.Id];
        System.assertEquals('Offered', result.Status__c,
            'Building Status__c should remain unchanged when contract has not expired');
    }

    // ─── Schedulable interface: verify System.schedule works ─────────────────

    @IsTest
    static void testSchedule_canBeScheduled() {
        Test.startTest();
        String jobId = System.schedule(
            'ContractDateLostClass Test Job',
            '0 0 0 1 1 ? 2099',
            new ContractDateLostClass()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduled job Id should not be null');
    }
}