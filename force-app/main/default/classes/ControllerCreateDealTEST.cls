@IsTest
private class ControllerCreateDealTEST {

    // ─── Test Data Setup ─────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        insert new Account(Name = 'Test Account');

        
        // Site__c lookup filter (1 AND 2): Opp RT = Offices AND Unit_Record_Type__c contains 'Offices'
        insert new Center__c(
            Name                = 'Residential Center',
            Unit_Record_Type__c = 'Residential'
        );

        // Site__c lookup filter (8 AND 9): Opp RT = Residential Property AND Unit_Record_Type__c = 'Residential'
        insert new Center__c(
            Name                = 'Residential Center',
            Unit_Record_Type__c = 'Residential',
            RecordTypeId        = Schema.SObjectType.Center__c
                                      .getRecordTypeInfosByName()
                                      .get('Residential Property')
                                      .getRecordTypeId()
        );

        insert new Building__c(
            Name                       = 'Test Building',
            LandSellableAreaSqm__c     = 1000,
            VillaSellableAreaSqm__c    = 2000,
            Asking_Price__c            = 500000,
            Total_Selling_Price_SAR__c = 500000,
            Center_Name__c             = [SELECT Id FROM Center__c WHERE Name = 'Residential Center' LIMIT 1].Id,
            RecordTypeId               = Schema.SObjectType.Building__c
                                             .getRecordTypeInfosByName()
                                             .get('Residential')
                                             .getRecordTypeId()
        );

        Id ppRtId = Schema.SObjectType.PaymentPlan__c
                        .getRecordTypeInfosByName()
                        .get('Residential Property')
                        .getRecordTypeId();

        insert new PaymentPlan__c(
            Name         = 'Test Plan',
            RecordTypeId = ppRtId
        );
    }

    // ─── getRecordTypeId ─────────────────────────────────────────────────────
    // Covers: blank sObjectName, blank recordTypeName, unknown RT name, valid case

    @IsTest
    static void testGetRecordTypeId() {
        System.assertEquals(null, ControllerCreateDeal.getRecordTypeId(null, 'Residential'),
            'Null sObjectName should return null');

        System.assertEquals(null, ControllerCreateDeal.getRecordTypeId('Opportunity', null),
            'Null recordTypeName should return null');

        System.assertEquals(null, ControllerCreateDeal.getRecordTypeId('Opportunity', 'NonExistentRT_XYZ'),
            'Unknown record type name should return null');

        Id rtId = ControllerCreateDeal.getRecordTypeId('Opportunity', 'Residential');
        System.assertNotEquals(null, rtId, 'Valid record type name should return an Id');
    }

    // ─── getAllPaymentPlans + getBulding ──────────────────────────────────────

    @IsTest
    static void testGetAllPaymentPlansAndGetBuilding() {
        PaymentPlan__c plan = [SELECT Id, RecordTypeId FROM PaymentPlan__c LIMIT 1];
        Building__c b       = [SELECT Id FROM Building__c LIMIT 1];

        Test.startTest();
        List<PaymentPlan__c> plans = ControllerCreateDeal.getAllPaymentPlans(plan.RecordTypeId);
        Building__c result         = ControllerCreateDeal.getBulding(b.Id);
        Test.stopTest();

        System.assert(plans.size() >= 1, 'Should return at least the test PaymentPlan');
        System.assertEquals(b.Id, result.Id, 'getBulding should return the correct Building record');
    }

    // ─── createDeal ──────────────────────────────────────────────────────────

    @IsTest
    static void testCreateDeal_success() {
        Building__c b = [SELECT Id FROM Building__c LIMIT 1];
        Account a     = [SELECT Id FROM Account LIMIT 1];
        Center__c c   = [SELECT Id FROM Center__c WHERE Name = 'Residential Center' LIMIT 1];

        Test.startTest();
        ControllerCreateDeal.createDeal(
            b.Id, 'Test Deal', String.valueOf(Date.today()),
            'Offered', 'Residential', c.Id, a.Id
        );
        Test.stopTest();

        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Test Deal' LIMIT 1];
        System.assertNotEquals(null, opp.Id, 'Opportunity should have been created');
        System.assertEquals('Offered', opp.StageName, 'StageName should match the stage argument');

        Integer dbCount = [SELECT COUNT() FROM Deal_Building__c WHERE Deal__c = :opp.Id];
        System.assertEquals(1, dbCount, 'Exactly one Deal_Building__c should have been created');
    }

    // ─── Exception branches: invalid record type in both create methods ───────

    @IsTest
    static void testCreateDeal_invalidRecordType_throwsException() {
        Building__c b = [SELECT Id FROM Building__c LIMIT 1];

        try {
            ControllerCreateDeal.createDeal(
                b.Id, 'X', String.valueOf(Date.today()), 'Offered', 'NonExistentRT_XYZ', null, null
            );
            System.assert(false, 'createDeal with invalid RT should throw AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException correctly thrown by createDeal');
        }

        try {
            ControllerCreateDeal.createDealWithPaymentPlan(
                b.Id, 'X', String.valueOf(Date.today()), 'Offered', 'NonExistentRT_XYZ', null, null, null
            );
            System.assert(false, 'createDealWithPaymentPlan with invalid RT should throw AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException correctly thrown by createDealWithPaymentPlan');
        }
    }

    // ─── createDealWithPaymentPlan ────────────────────────────────────────────

    @IsTest
    static void testCreateDealWithPaymentPlan_success() {
        Building__c    b    = [SELECT Id FROM Building__c LIMIT 1];
        Account        a    = [SELECT Id FROM Account LIMIT 1];
        Center__c      c    = [SELECT Id FROM Center__c WHERE Name = 'Residential Center' LIMIT 1];
        PaymentPlan__c plan = [SELECT Id FROM PaymentPlan__c LIMIT 1];

        Test.startTest();
        ControllerCreateDeal.createDealWithPaymentPlan(
            b.Id, 'Test Deal PP', String.valueOf(Date.today()),
            'Offered', 'Residential Property', c.Id, a.Id, plan.Id
        );
        Test.stopTest();

        Opportunity opp = [SELECT Id, PaymentPlan__c FROM Opportunity WHERE Name = 'Test Deal PP' LIMIT 1];
        System.assertNotEquals(null, opp.Id, 'Opportunity should have been created');
        System.assertEquals(plan.Id, opp.PaymentPlan__c, 'PaymentPlan__c should be linked to the Opportunity');

        Integer dbCount = [SELECT COUNT() FROM Deal_Building__c WHERE Deal__c = :opp.Id];
        System.assertEquals(1, dbCount, 'Exactly one Deal_Building__c should have been created');
    }
}