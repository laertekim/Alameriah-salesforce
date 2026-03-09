@IsTest
private class DealBuildingServiceTest {

    private static Opportunity createOpportunity(String name) {
        Opportunity opp = new Opportunity(
            Name = name,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(20)
        );
        insert opp;
        return opp;
    }

    private static Building__c createBuilding(String name) {
        Building__c building = new Building__c(Name = name);
        insert building;
        return building;
    }

    private static Deal_Building__c createDealBuilding(Id oppId, Id buildingId, Decimal totalSelling) {
        Deal_Building__c db = new Deal_Building__c(
            Deal__c = oppId,
            Building__c = buildingId,
            Total_Selling_Price_SAR__c = totalSelling
        );
        insert db;
        db.Total_Selling_Price_SAR__c = totalSelling;
        update db;
        return db;
    }

    @IsTest
    static void setTotalSellingPrice_shouldPopulateValueOnInputRecord() {
        Opportunity opp = new Opportunity(
            Name = 'Service Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        Building__c building = new Building__c(
            Name = 'Service Test Building'
        );
        insert building;

        Deal_Building__c dealBuilding = new Deal_Building__c(
            Deal__c = opp.Id,
            Building__c = building.Id
        );

        Test.startTest();
        new DealBuildingService().setTotalSellingPrice(new List<Deal_Building__c>{ dealBuilding });
        Test.stopTest();

        System.assertEquals(0, dealBuilding.Total_Selling_Price_SAR__c);
    }

    @IsTest
    static void updateRelatedOpportunitiesOnInsert_shouldRecalculateAmountWithOtherCharges() {
        Opportunity opp = createOpportunity('Service Insert Opp');
        Building__c building = createBuilding('Service Insert Building');
        Deal_Building__c db1 = createDealBuilding(opp.Id, building.Id, 120);
        Deal_Building__c db2 = createDealBuilding(opp.Id, building.Id, 80);
        insert new Other_Charges__c(Deal__c = opp.Id, Amount__c = 50);

        Test.startTest();
        new DealBuildingService().updateRelatedOpportunitiesOnInsert(new List<Deal_Building__c>{ db1, db2 });
        Test.stopTest();

        Opportunity updated = [SELECT Amount, Unit_Number__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(250, updated.Amount, 'Amount should be sum(Deal_Building) + Other Charges');
        System.assertEquals(null, updated.Unit_Number__c, 'Reset should keep Unit_Number__c null for this scenario');
    }

    @IsTest
    static void handleUpdate_shouldRecalculateWhenRelevantFieldChanges() {
        Opportunity opp = createOpportunity('Service Update Opp');
        Building__c building = createBuilding('Service Update Building');
        Deal_Building__c db = createDealBuilding(opp.Id, building.Id, 100);

        DealBuildingService service = new DealBuildingService();
        service.updateRelatedOpportunitiesOnInsert(new List<Deal_Building__c>{ db });

        Deal_Building__c oldDb = db.clone(false, true, false, false);
        oldDb.Id = db.Id;
        db.Total_Selling_Price_SAR__c = 260;
        update db;

        Test.startTest();
        service.handleUpdate(new List<Deal_Building__c>{ db }, new Map<Id, Deal_Building__c>{ db.Id => oldDb });
        Test.stopTest();

        Opportunity updated = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(260, updated.Amount);
    }

    @IsTest
    static void handleUpdate_shouldRecalculateBothOpportunitiesWhenDealChanges() {
        Opportunity oppA = createOpportunity('Service Move Opp A');
        Opportunity oppB = createOpportunity('Service Move Opp B');
        Building__c building = createBuilding('Service Move Building');
        Deal_Building__c db = createDealBuilding(oppA.Id, building.Id, 300);

        DealBuildingService service = new DealBuildingService();
        service.updateRelatedOpportunitiesOnInsert(new List<Deal_Building__c>{ db });

        Deal_Building__c oldDb = db.clone(false, true, false, false);
        oldDb.Id = db.Id;
        db.Deal__c = oppB.Id;
        update db;

        Test.startTest();
        service.handleUpdate(new List<Deal_Building__c>{ db }, new Map<Id, Deal_Building__c>{ db.Id => oldDb });
        Test.stopTest();

        Opportunity updatedA = [SELECT Amount FROM Opportunity WHERE Id = :oppA.Id];
        Opportunity updatedB = [SELECT Amount FROM Opportunity WHERE Id = :oppB.Id];
        System.assertEquals(0, updatedA.Amount, 'Old opportunity should be reset');
        System.assertEquals(300, updatedB.Amount, 'New opportunity should receive aggregation');
    }

    @IsTest
    static void handleDelete_shouldResetOpportunityWhenNoDealBuildingsRemain() {
        Opportunity opp = createOpportunity('Service Delete Opp');
        Building__c building = createBuilding('Service Delete Building');
        Deal_Building__c db = createDealBuilding(opp.Id, building.Id, 400);

        DealBuildingService service = new DealBuildingService();
        service.updateRelatedOpportunitiesOnInsert(new List<Deal_Building__c>{ db });

        delete db;

        Test.startTest();
        service.handleDelete(new List<Deal_Building__c>{ db });
        Test.stopTest();

        Opportunity updated = [SELECT Amount, Unit_Size_SQM__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(0, updated.Amount);
        System.assertEquals(0, updated.Unit_Size_SQM__c);
    }

    @IsTest
    static void publicMethods_shouldExecuteWithEmptyInputs() {
        DealBuildingService service = new DealBuildingService();

        Test.startTest();
        service.updateRelatedOpportunitiesOnInsert(new List<Deal_Building__c>());
        service.handleUpdate(new List<Deal_Building__c>(), new Map<Id, Deal_Building__c>());
        service.handleDelete(new List<Deal_Building__c>());
        Test.stopTest();

        System.assert(true, 'Methods executed without exceptions.');
    }
}
