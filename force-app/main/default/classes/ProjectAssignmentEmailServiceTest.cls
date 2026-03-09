@IsTest
private class ProjectAssignmentEmailServiceTest {

    @TestSetup
    static void makeData() {
        insert new Project__c(Name = 'Test Project');
        insert new Executive_Report__c();
    }

    // ─── Direct service call: with Executive Report ───────────────────────────
    // Covers the executiveReportLink-building branch (pa.Executive_Report__c != null)

    @IsTest
    static void testSendNotification_withExecutiveReport() {
        Project__c project       = [SELECT Id FROM Project__c LIMIT 1];
        Executive_Report__c exec = [SELECT Id FROM Executive_Report__c LIMIT 1];

        // Insert without Comments__c so the trigger does NOT fire (no spurious send)
        Project_Assignment__c pa = new Project_Assignment__c(
            Project__c          = project.Id,
            Executive_Report__c = exec.Id
        );
        insert pa;

        Test.startTest();
        ProjectAssignmentEmailService.sendCommentNotification(
            new List<Project_Assignment__c>{ pa }
        );
        Test.stopTest();

        System.assert(Limits.getEmailInvocations() >= 1,
            'sendEmail should have been called with Executive Report set');
    }

    // ─── Direct service call: without Executive Report ────────────────────────
    // Covers the empty executiveReportLink branch (pa.Executive_Report__c == null)

    @IsTest
    static void testSendNotification_withoutExecutiveReport() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Project_Assignment__c pa = new Project_Assignment__c(
            Project__c = project.Id
        );
        insert pa;

        Test.startTest();
        ProjectAssignmentEmailService.sendCommentNotification(
            new List<Project_Assignment__c>{ pa }
        );
        Test.stopTest();

        System.assert(Limits.getEmailInvocations() >= 1,
            'sendEmail should have been called even without an Executive Report');
    }

    // ─── Trigger: after insert with Comments__c populated ─────────────────────
    // Covers ProjectAssignmentCommentTrigger → isInsert branch

    @IsTest
    static void testTrigger_insertWithComment() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        insert new Project_Assignment__c(
            Project__c = project.Id,
            Comments__c = 'Comment added on insert'
        );
        Test.stopTest();

        System.assert(Limits.getEmailInvocations() >= 1,
            'Email should be sent when Comments__c is populated on insert');
    }

    // ─── Trigger: after update when Comments__c changes ───────────────────────
    // Covers ProjectAssignmentCommentTrigger → isUpdate branch

    @IsTest
    static void testTrigger_updateComment() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        // Insert without Comments__c — trigger fires but no email is sent
        Project_Assignment__c pa = new Project_Assignment__c(
            Project__c = project.Id
        );
        insert pa;

        Test.startTest();
        pa.Comments__c = 'Comment added via update';
        update pa;
        Test.stopTest();

        System.assert(Limits.getEmailInvocations() >= 1,
            'Email should be sent when Comments__c is changed on update');
    }

    // ─── Trigger: no email when Comments__c is unchanged on update ────────────

    @IsTest
    static void testTrigger_noEmailWhenCommentUnchanged() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Project_Assignment__c pa = new Project_Assignment__c(
            Project__c  = project.Id,
            Comments__c = 'Existing comment'
        );
        insert pa;

        Integer emailsBefore = Limits.getEmailInvocations();

        Test.startTest();
        pa.Assignment_Description__c = 'Changed description only';
        update pa;
        Test.stopTest();

        System.assertEquals(emailsBefore, Limits.getEmailInvocations(),
            'No new email should be sent when Comments__c is not changed');
    }
}
