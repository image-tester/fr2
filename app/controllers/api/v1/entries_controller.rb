class Api::V1::EntriesController < ApiController
  BASIC_FIELDS = [:title, :type, :abstract, :document_number, :html_url, :pdf_url, :public_inspection_pdf_url, :publication_date, :agenices, :excerpts]

  def index
    respond_to do |wants|
      wants.json do
        cache_for 1.day
        search = EntrySearch.new(params)
        fields = specified_fields || BASIC_FIELDS

        render_search(search) do |result| 
          entry_data(result, fields)
        end
      end
    end
  end
  
  def show
    respond_to do |wants|
      wants.json do
        cache_for 1.day

        fields = specified_fields || all_fields 

        render_one_or_more(Entry, params[:id]) do |entry|
          entry_data(entry, fields)
        end
      end
    end
  end
 
  private

  def specified_fields
    if params[:fields]
      params[:fields].reject(&:blank?).map{|f| f.to_s.to_sym}
    end
  end

  def entry_data(entry, fields)
    Hash[ fields.map do |field|
      calculator = field_calculators[field]

      if calculator.nil?
        raise UnknownFieldError.new("#{field} is not a valid field")
      end

      [field, calculator.call(entry)]
    end]
  end

  def field_calculators
    @field_calculators ||= {
      :abstract                  => Proc.new{|e| e.abstract},
      :abstract_html_url         => Proc.new{|e| entry_abstract_url(e)},
      :action                    => Proc.new{|e| e.action},
      :agencies                  => Proc.new{|e| agencies_data(e)},
      :body_html_url             => Proc.new{|e| entry_full_text_url(e)},
      :cfr_references            => Proc.new{|e| cfr_references_info(e)}, 
      :comments_close_on         => Proc.new{|e| e.comments_close_on},
      :dates                     => Proc.new{|e| e.dates},
      :docket_id                 => Proc.new{|e| e.docket_numbers.first.try(:number)}, # backwards compatible for now
      :docket_ids                => Proc.new{|e| e.docket_numbers.map(&:number)},
      :document_number           => Proc.new{|e| e.document_number},
      :effective_on              => Proc.new{|e| e.effective_on},
      :end_page                  => Proc.new{|e| e.end_page},
      :excerpts                  => Proc.new{|e| (e.excerpts.raw_text || result.excerpts.abstract) if e.respond_to?(:excerpts)},
      :full_text_xml_url         => Proc.new{|e| e.full_xml_updated_at ? entry_xml_url(e) : nil},
      :html_url                  => Proc.new{|e| entry_url(e)},
      :json_url                  => Proc.new{|e| api_v1_entry_url(e.document_number, :format => :json)},
      :mods_url                  => Proc.new{|e| e.source_url(:mods)},
      :pdf_url                   => Proc.new{|e| e.source_url('pdf')}, 
      :public_inspection_pdf_url => Proc.new{|e| e.public_inspection_document.try(:pdf).try(:url)},
      :publication_date          => Proc.new{|e| e.publication_date},
      :regulation_id_number_info => Proc.new{|e| regulation_id_number_info(e)},
      :regulation_id_numbers     => Proc.new{|e| e.entry_regulation_id_numbers.map(&:regulation_id_number)},
      :regulations_dot_gov_url   => Proc.new{|e| e.regulationsdotgov_url},
      :start_page                => Proc.new{|e| e.start_page},
      :subtype                   => Proc.new{|e| e.presidential_document_type.try(:name)}, 
      :title                     => Proc.new{|e| e.title},
      :type                      => Proc.new{|e| e.entry_type},
      :volume                    => Proc.new{|e| e.volume},
    }
  end

  def all_fields
    field_calculators.keys - [:excerpts]
  end

  def index_url(options)
    api_v1_entries_url(options)
  end


  def agencies_data(entry)
    entry.agency_names.map do |agency_name|
      agency = agency_name.agency
      if agency
        {
          :raw_name => agency_name.name,
          :name     => agency.name,
          :id       => agency.id,
          :url      => agency_url(agency),
          :json_url => api_v1_agency_url(agency.id, :format => :json),
          :parent_id => agency.parent_id
        }
      else
        {
          :raw_name => agency_name.name
        }
      end
    end
  end

  def cfr_references_info(entry)
    entry.entry_cfr_references.map do |cfr_reference|
      {:title => cfr_reference.title, :part => cfr_reference.part}
    end
  end

  def regulation_id_number_info(entry)
    values = entry.entry_regulation_id_numbers.map(&:regulation_id_number).map do |rin|
      regulatory_plan = entry.current_regulatory_plans.detect{|r| r.regulation_id_number == rin}

      if regulatory_plan
        regulatory_plan_info = {
          :xml_url => regulatory_plan.source_url(:xml),
          :issue => regulatory_plan.issue,
          :title => regulatory_plan.title,
          :priority_category => regulatory_plan.priority_category
        }
      end
      [rin, regulatory_plan_info]
    end
    
    Hash[*values.flatten]
  end
end
