public class FieldDescriptor {
    public String apiName { get; private set; }
    public String label { get; private set; }
    private Object rawValue;
    private Schema.DisplayType fieldType;
    
    public FieldDescriptor(String apiName, String label, Object rawValue, Schema.DisplayType fieldType) {
        this.apiName = apiName;
        this.label = label;
        this.rawValue = rawValue;
        this.fieldType = fieldType;
    }
    
    public String getLabel() {
        return this.label;
    }
    
    public String getFormattedValue() {
        if (this.rawValue == null) {
            return '';
        }
        
        switch on this.fieldType {
            when DATE {
                return ((Date) this.rawValue).format();
            }
            when DATETIME {
                return ((DateTime) this.rawValue).format('yyyy-MM-dd HH:mm:ss');
            }
            when CURRENCY, DOUBLE, PERCENT {
                return String.valueOf(this.rawValue);
            }
            when BOOLEAN {
                return (Boolean) this.rawValue ? 'Yes' : 'No';
            }
            when else {
                return String.valueOf(this.rawValue);
            }
        }
    }
    
    public String formattedValue {
        get {
            return getFormattedValue();
        }
    }
}