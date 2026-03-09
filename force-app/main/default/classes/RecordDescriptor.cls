public class RecordDescriptor {
    private SObject record {get; set;}
    public List<FieldDescriptor> fields { get; private set; }
    
    public RecordDescriptor(SObject record) {
        this.record = record;
        this.fields = new List<FieldDescriptor>();
    }
    
    public void addField(FieldDescriptor field) {
        this.fields.add(field);
    }
    
    public List<FieldDescriptor> getFields() {
        return this.fields;
    }
    
    public SObject getRecord() {
        return this.record;
    }
}