/**
 * Test coverage for DealBildingTrigger (legacy - marked as deactivated).
 * The trigger delegates to DealBildingTriggerHandler for all four events.
 * If the trigger is inactive in Setup, DML will not execute its code;
 * DealBildingTriggerHandlerTest covers the handler directly in that case.
 */
@IsTest
private class DealBildingTriggerTest {

    @TestSetup
    static void makeData() {
        insert new Account(Name = 'Test Account');

        Center__c center = new Center__c(
            Name                = 'Residential Center',
            Unit_Record_Type__c = 'Residential'
        );
        insert center;

        Building__c bldg = new Building__c(
            Name                       = 'Test Building',
            Total_Selling_Price_SAR__c = 100000,
            Center_Name__c             = center.Id
        );
        insert bldg;

        Id rtId = Schema.SObjectType.Opportunity
                      .getRecordTypeInfosByName().get('Residential').getRecordTypeId();

        insert new Opportunity(
            Name         = 'Test Deal',
            StageName    = 'Offered',
            CloseDate    = Date.today().addDays(30),
            AccountId    = [SELECT Id FROM Account LIMIT 1].Id,
            RecordTypeId = rtId,
            Site__c      = center.Id
        );
    }

    // Fires before insert + after insert events on DealBildingTrigger
    @IsTest
    static void testTrigger_insert() {
        Opportunity opp  = [SELECT Id FROM Opportunity LIMIT 1];
        Building__c bldg = [SELECT Id FROM Building__c LIMIT 1];

        Test.startTest();
        insert new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
        Test.stopTest();

        System.assertEquals(1,
            [SELECT COUNT() FROM Deal_Building__c WHERE Deal__c = :opp.Id],
            'Deal_Building__c should be inserted');
    }

    // Fires after update event on DealBildingTrigger
    @IsTest
    static void testTrigger_update() {
        Opportunity opp  = [SELECT Id FROM Opportunity LIMIT 1];
        Building__c bldg = [SELECT Id FROM Building__c LIMIT 1];

        Deal_Building__c db = new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
        insert db;

        Test.startTest();
        db.Total_Selling_Price_SAR__c = 200000;
        update db;
        Test.stopTest();

        Deal_Building__c result = [SELECT Total_Selling_Price_SAR__c FROM Deal_Building__c WHERE Id = :db.Id];
        System.assertEquals(200000, result.Total_Selling_Price_SAR__c,
            'Total_Selling_Price_SAR__c should reflect the update');
    }

    // Fires after delete event on DealBildingTrigger
    @IsTest
    static void testTrigger_delete() {
        Opportunity opp  = [SELECT Id FROM Opportunity LIMIT 1];
        Building__c bldg = [SELECT Id FROM Building__c LIMIT 1];

        Deal_Building__c db = new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
        insert db;

        Test.startTest();
        delete db;
        Test.stopTest();

        System.assertEquals(0,
            [SELECT COUNT() FROM Deal_Building__c WHERE Id = :db.Id],
            'Deal_Building__c should have been deleted');
    }
}