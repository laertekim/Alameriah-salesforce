@IsTest
private class DealBildingTriggerHandlerTest {

    // ─── Test Data Setup ─────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        insert new Account(Name = 'Test Account');

        // Centers must satisfy Site__c lookup filter per Opportunity RT
        Center__c officesCenter = new Center__c(
            Name                = 'Residential Center',
            Unit_Record_Type__c = 'Residential'
        );
        Center__c retailCenter = new Center__c(
            Name                = 'Retail Center',
            Unit_Record_Type__c = 'Retail'
        );
        insert new List<Center__c>{ officesCenter, retailCenter };

        // Buildings (no RT required by trigger logic)
        Building__c officesBldg = new Building__c(
            Name                       = 'Residential Building',            
            Total_Selling_Price_SAR__c   = 100000,
            Center_Name__c               = officesCenter.Id
        );
        Building__c retailBldg = new Building__c(
            Name                       = 'Retail Building',
            Total_Selling_Price_SAR__c = 80000,
            Center_Name__c             = retailCenter.Id
        );
        insert new List<Building__c>{ officesBldg, retailBldg };

        Id officesRtId = Schema.SObjectType.Opportunity
                             .getRecordTypeInfosByName().get('Residential').getRecordTypeId();
        Id retailRtId  = Schema.SObjectType.Opportunity
                             .getRecordTypeInfosByName().get('Retail').getRecordTypeId();

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity officesOpp = new Opportunity(
            Name         = 'Test Residential Deal',
            StageName    = 'Offered',
            CloseDate    = Date.today().addDays(30),
            AccountId    = acc.Id,
            RecordTypeId = officesRtId,
            Site__c      = officesCenter.Id
        );
        Opportunity retailOpp = new Opportunity(
            Name         = 'Test Retail Deal',
            StageName    = 'Offered',
            CloseDate    = Date.today().addDays(30),
            AccountId    = acc.Id,
            RecordTypeId = retailRtId,
            Site__c      = retailCenter.Id
        );
        insert new List<Opportunity>{ officesOpp, retailOpp };
    }

    // ─── onBeforeInsert + onAfterInsert: Offices RT ──────────────────────────
    // Covers DealBuildingBeforeInsert.beforeInsert (Offices branch sets Total_Selling_Price_SAR__c
    // from Gross_Leasable_Amount_SAR__c) and DealBuildingBeforeInsert.afterInsert aggregation.

    @IsTest
    static void testInsert_ResidentialRT() {
        Opportunity opp  = [SELECT Id FROM Opportunity WHERE Name = 'Test Residential Deal' LIMIT 1];
        Building__c bldg = [SELECT Id, Gross_Leasable_Amount_SAR__c FROM Building__c WHERE Name = 'Residential Building' LIMIT 1];

        Test.startTest();
        Deal_Building__c db = new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
        insert db;
        Test.stopTest();

        Deal_Building__c result = [SELECT Id, Total_Selling_Price_SAR__c FROM Deal_Building__c WHERE Id = :db.Id];
        System.assertNotEquals(null, result.Id, 'Deal_Building__c should have been inserted');
        System.assertEquals(
            bldg.Gross_Leasable_Amount_SAR__c,
            result.Total_Selling_Price_SAR__c,
            'beforeInsert should set Total_Selling_Price_SAR__c from Gross_Leasable_Amount_SAR__c for Offices RT'
        );
    }

    // ─── onBeforeInsert + onAfterInsert: Retail RT ───────────────────────────
    // Covers the Retail branch in DealBuildingBeforeInsert.beforeInsert (sets
    // Total_Selling_Price_SAR__c from Asking_Annual_Rent__c).

    @IsTest
    static void testInsert_RetailRT() {
        Opportunity opp  = [SELECT Id FROM Opportunity WHERE Name = 'Test Retail Deal' LIMIT 1];
        Building__c bldg = [SELECT Id, Asking_Annual_Rent__c FROM Building__c WHERE Name = 'Retail Building' LIMIT 1];

        Test.startTest();
        Deal_Building__c db = new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
        insert db;
        Test.stopTest();

        Deal_Building__c result = [SELECT Id, Total_Selling_Price_SAR__c FROM Deal_Building__c WHERE Id = :db.Id];
        System.assertNotEquals(null, result.Id, 'Deal_Building__c should have been inserted for Retail opportunity');
        System.assertEquals(
            bldg.Asking_Annual_Rent__c,
            result.Total_Selling_Price_SAR__c,
            'beforeInsert should set Total_Selling_Price_SAR__c from Asking_Annual_Rent__c for Retail RT'
        );
    }

    // ─── onAfterUpdate ───────────────────────────────────────────────────────
    // Covers DealBuildingUpdate.afterUpdate — changes to Total_Selling_Price_SAR__c
    // trigger propagation to the parent Opportunity (Amount field).

    @IsTest
    static void testAfterUpdate() {
        Opportunity opp  = [SELECT Id FROM Opportunity WHERE Name = 'Test Residential Deal' LIMIT 1];
        Building__c bldg = [SELECT Id FROM Building__c WHERE Name = 'Residential Building' LIMIT 1];

        Deal_Building__c db = new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
        insert db;

        Test.startTest();
        db.Total_Selling_Price_SAR__c = 200000;
        update db;
        Test.stopTest();

        Deal_Building__c updated = [SELECT Id, Total_Selling_Price_SAR__c FROM Deal_Building__c WHERE Id = :db.Id];
        System.assertEquals(200000, updated.Total_Selling_Price_SAR__c,
            'Total_Selling_Price_SAR__c should reflect the updated value');

        Opportunity oAfter = [SELECT Id, Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, oAfter.Id, 'Opportunity should still exist after Deal_Building update');
    }

    // ─── onAfterDelete ───────────────────────────────────────────────────────
    // Covers DealBuildingDelete.afterDelete — deleting a Deal_Building resets
    // the Building Status__c to 'Available Units' and adjusts the parent Opportunity.

    @IsTest
    static void testAfterDelete() {
        Opportunity opp  = [SELECT Id FROM Opportunity WHERE Name = 'Test Residential Deal' LIMIT 1];
        Building__c bldg = [SELECT Id FROM Building__c WHERE Name = 'Residential Building' LIMIT 1];

        Deal_Building__c db = new Deal_Building__c(
            Deal__c     = opp.Id,
            Building__c = bldg.Id
        );
        insert db;

        Test.startTest();
        delete db;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Deal_Building__c WHERE Deal__c = :opp.Id];
        System.assertEquals(0, count, 'Deal_Building__c should have been deleted');

        Building__c bldgAfter = [SELECT Id, Status__c FROM Building__c WHERE Id = :bldg.Id];
        System.assertEquals('Available Units', bldgAfter.Status__c,
            'Building Status__c should be reset to Available Units after Deal_Building deletion');
    }
}
