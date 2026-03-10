public class BuildingTriggerHandler {

    public static void setResidentialMirrorFields(List<Building__c> buildings) {
        Id residentialRTId = Schema.SObjectType.Building__c
            .getRecordTypeInfosByName().get('Residential')?.getRecordTypeId();

        if (residentialRTId == null) return;

        for (Building__c b : buildings) {
            if (b.RecordTypeId == residentialRTId) {
                b.VillaArea__c = b.Area__c;
                b.VillaSellableAreaSqm__c = b.Unit_Area_Sqm__c;
            }
        }
    }
}