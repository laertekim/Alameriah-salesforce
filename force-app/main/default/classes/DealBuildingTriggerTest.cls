/**
 * Test coverage for DealBuildingTrigger (active trigger).
 * Delegates to DealBuildingTriggerHandler → DealBuildingService for all four events.
 */
@IsTest
private class DealBuildingTriggerTest {

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

    // Fires before insert (setTotalSellingPrice) + after insert (updateRelatedOpportunitiesOnInsert)
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
            'Deal_Building__c should be inserted and trigger should complete without error');
    }

    // Fires after update (handleUpdate)
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
        db.Total_Selling_Price_SAR__c = 150000;
        update db;
        Test.stopTest();

        Deal_Building__c result = [SELECT Total_Selling_Price_SAR__c FROM Deal_Building__c WHERE Id = :db.Id];
        System.assertEquals(150000, result.Total_Selling_Price_SAR__c,
            'Deal_Building__c should be updated and trigger should complete without error');
    }

    // Fires after delete (handleDelete) — verifies Building status is reset
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
            'Deal_Building__c should be deleted and trigger should complete without error');

        Building__c bldgAfter = [SELECT Status__c FROM Building__c WHERE Id = :bldg.Id];
        System.assertEquals('Available Units', bldgAfter.Status__c,
            'Building Status__c should be reset to Available Units after Deal_Building deletion');
    }
}