require 'csv'
require 'rubygems'
require 'bundler/setup'
Bundler.require


class FreshbooksInvoiceExporter
  def initialize(opts)
    @api_domain = opts[:api_domain]
    @api_token = opts[:api_token]
    @api_client = FreshBooks::Client.new(@api_domain, @api_token)
  end

  def export_all_invoices_to_file!
    CSV.open("invoices.csv", "w+") do |csv|
      csv << %w(ContactName EmailAddress POAddressLine1 POAddressLine2 POAddressLine3 POAddressLine4 POCity PORegion POPostalCode POCountry InvoiceNumber Reference InvoiceDate DueDate Total InventoryItemCode Description Quantity UnitAmount Discount AccountCode TaxType TaxAmount TrackingName1 TrackingOption1 TrackingName2 TrackingOption2)
      list = @api_client.invoice.list
      puts "Requesting invoices..."
      pages = list["invoices"]["pages"].to_i
      pages.times do |i|
        page = i + 1
        puts "Processing invoices (page #{page} of #{pages})"
        response = @api_client.invoice.list(page: page)
        response["invoices"]["invoice"].each do |invoice|
          invoice_date = due_date = Date.parse(invoice["date"]).strftime("%m/%d/%Y") # Our due date is the invoice date
          discount = invoice["discount"].to_i > 0 ? invoice["discount"] : nil
          invoice["lines"]["line"].each do |line|
            next if line["unit_cost"].to_f == 0.0 # Freshbooks ends up creating lots of empty invoice line items
            csv << [
                      invoice["organization"],      # ContactName
                      nil,                          # EmailAddress
                      nil,                          # POAddressLine1
                      nil,                          # POAddressLine2
                      nil,                          # POAddressLine3
                      nil,                          # POAddressLine4
                      nil,                          # POCity
                      nil,                          # PORegion
                      nil,                          # POPostalCode
                      nil,                          # POCountry
                      invoice["number"],            # InvoiceNumber
                      nil,                          # Reference
                      invoice_date,                 # InvoiceDate
                      due_date,                     # DueDate
                      nil,                          # Total
                      nil,                          # InventoryItemCode
                      line["description"],          # Description
                      line["quantity"],             # Quantity
                      line["unit_cost"],            # UnitAmount
                      discount,                     # Discount
                      400,                          # AccountCode
                      "Tax Exempt (0%)",            # TaxType
                      nil,                          # TaxAmount
                      nil,                          # TrackingName1
                      nil,                          # TrackingOption1
                      nil,                          # TrackingName2
                      nil,                          # TrackingOption2
                    ]
          end
        end
      end
    end
  end

end

exporter = FreshbooksInvoiceExporter.new(api_domain: ENV['FRESHBOOKS_API_DOMAIN'], api_token: ENV['FRESHBOOKS_API_TOKEN'])
exporter.export_all_invoices_to_file!
