public interface IFieldConfigurationProvider {
    List<String> getOpportunityFields();
    List<String> getPaymentScheduleFields();
    List<String> getOtherChargeFields();
}