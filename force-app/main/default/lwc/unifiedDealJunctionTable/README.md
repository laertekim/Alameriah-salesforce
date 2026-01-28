# Unified Deal Junction Table Component

This is a unified Lightning Web Component that replaces the three separate components:
- `residantialJunkTable` (for Residential record type)
- `dealJunctionObjectTable` (for Offices record type)
- `retailDealJunctionObjectTable` (for Retail record type)

## Features

- **Configurable Columns**: Define which columns to display for both the "Deal Units" table and the "Units" table
- **Configurable Filters**: Define which filter dropdowns to show
- **Record Type Based**: Automatically configures based on the Building record type (Residential, Offices, or Retail)
- **Customizable**: Can accept a custom JSON configuration to override defaults

## Usage

### Basic Usage (Using Default Configuration)

1. Add the component to a Lightning Record Page
2. Set the `recordTypeName` property to one of:
   - `Residential`
   - `Offices`
   - `Retail`
3. The component will automatically use the default column and filter configuration for that record type

### Advanced Usage (Custom Configuration)

You can provide a custom JSON configuration via the `columnConfig` property:

```json
{
  "dealColumns": [
    {
      "fieldApiName": "Zone__c",
      "label": "Zone",
      "type": "text"
    },
    {
      "fieldApiName": "Total_Selling_Price_SAR__c",
      "label": "Total Selling Price",
      "type": "currency"
    }
  ],
  "unitColumns": [
    {
      "fieldApiName": "Status__c",
      "label": "Status",
      "type": "text"
    }
  ],
  "filterFields": [
    {
      "fieldApiName": "Zone__c",
      "label": "Zone",
      "schemaField": "Building__c.Zone__c"
    }
  ]
}
```

### Column Types

- `text`: Plain text display
- `number`: Formatted number display
- `currency`: Currency formatted display (SAR)

### Default Configurations

#### Residential
- **Deal Columns**: Zone, Tower Name, Level, Apartment Type, Unit No, View, Unit Area/Sqm, Min Weighted, Min Weighted Rate, Client Min Price SAR, Ask Weighted, Ask Weighted Rate, Client Asking Price SAR, Total Selling Price SAR
- **Unit Columns**: Status, Zone, Tower Name, Level, Apartment Type, Unit No, View, Unit Area/Sqm, Min Weighted, Min Weighted Rate, Client Min Price SAR, Ask Weighted, Ask Weighted Rate, Client Asking Price SAR
- **Filters**: Zone, Tower Name, Status, Level/Floor, Apartment Type, Unit No, View

#### Offices
- **Deal Columns**: Zone, Tower Name, Level, Building Type, Unit No, View, Unit Area Sqm (NSA), Lobby Area, Service Area, Terrace Area, Gross Area Size, Total Leasable Area, Leasing Rate, Price Sqm SAR /Lobby, Price Sqm SAR /Services, Price Sqm SAR /Terraces, Total (NSA), Total Prices (Lobby Areas), Total Prices (Services Areas), Total Prices (Terraces Areas), Gross Leasable Amount SAR, Total Selling Price SAR
- **Unit Columns**: Status, Zone, Tower Name, Level, Building Type, Unit No, View, Unit Area Sqm (NSA), Lobby Area, Service Area, Terrace Area, Gross Area Size, Total Leasable Area, Leasing Rate, Price Sqm SAR /Lobby, Price Sqm SAR /Services, Price Sqm SAR /Terraces, Total (NSA), Total Prices (Lobby Areas), Total Prices (Services Areas), Total Prices (Terraces Areas), Gross Leasable Amount SAR, Total Selling Price SAR, Agent Commission 8%, Edara Commission 2%
- **Filters**: Zone, Tower Name, Building Type, Status, Level, Unit No, View

#### Retail
- **Deal Columns**: Level, Zone, Unit Type, Unit No, Unit Area/Sqm, Asking Price, Minimum Annual Rent, Asking Annual Rent, Total Selling Price SAR
- **Unit Columns**: Status, Level, Zone, Unit Type, Unit No, Unit Area/Sqm, Asking Price, Minimum Annual Rent, Asking Annual Rent
- **Filters**: Zone, Level, Unit Type, Unit No, Retail Category, Status

## Migration Guide

To migrate from the old components to the unified component:

1. **Replace the component** on your Lightning pages
2. **Set the recordTypeName** property:
   - For `residantialJunkTable` → Set `recordTypeName` to `"Residential"`
   - For `dealJunctionObjectTable` → Set `recordTypeName` to `"Offices"`
   - For `retailDealJunctionObjectTable` → Set `recordTypeName` to `"Retail"`
3. **Test thoroughly** to ensure all functionality works as expected
4. **Remove the old components** once migration is complete

## Component Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `recordId` | String | Yes | - | The ID of the Deal/Opportunity record |
| `recordTypeName` | String | No | `"Residential"` | The Building record type name |
| `columnConfig` | String | No | - | JSON string with custom column configuration |

## Notes

- The component uses the same Apex controller methods as the original components
- All existing functionality (add units, edit, delete) is preserved
- The component automatically loads picklist values for all filter fields
- Column labels support HTML (use `<br>` for line breaks)
