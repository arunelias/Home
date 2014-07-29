class Permit < ActiveRecord::Base
  has_many :permit_binary_details
  has_many :binaries, through: :permit_binary_details

  attr_accessor :confirmed_name,

                # Room Addition
                :addition_size, :addition_num_story,
                # Accessory Structure
                :acs_struct_size, :acs_struct_num_story,
                # Deck
                :deck_size, :deck_grade, :deck_dwelling_attach, :deck_exit_door,
                # Pool
                :pool_location, :pool_volume,
                # Cover
                :cover_material,
                # Window
                :window_replace_glass,
                # Door
                :door_replace_existing,
                # Wall
                :wall_general_changes,
                # Siding
                :siding_over_existing,
                # Floor
                :floor_covering

  # validates on permit_steps#new
  # validates_inclusion_of :addition, :in => [true], :message => "Please choose an improvement."
  validate :at_least_one_chosen

  # validates on permit_steps#answer_screener
  validates_presence_of :addition_size, :if => :only_if_screener_addition?, :message => "Please select the size of the room addition."
  validates_presence_of :addition_num_story, :if => :only_if_screener_addition?, :message => "Please select the number of stories for the room addition."

  validates_presence_of :acs_struct_size, :if => :only_if_screener_acs_struct?, :message => "Please select the size of the accessory structure."
  validates_presence_of :acs_struct_num_story, :if => :only_if_screener_acs_struct?, :message => "Please select the number of stories for the accessory structure."

  validates_presence_of :deck_size, :if => :only_if_screener_deck?, :message => "Please select the size of the deck."
  validates_presence_of :deck_grade, :if => :only_if_screener_deck?, :message => "Please select the grade of the deck."
  validates_presence_of :deck_dwelling_attach, :if => :only_if_screener_deck?, :message => "Please select whether the deck is attached to dwelling or not."
  validates_presence_of :deck_exit_door, :if => :only_if_screener_deck?, :message => "Please select whether the deck serves a required exit door or not."

  validates_presence_of :pool_location, :if => :only_if_screener_pool?, :message => "Please select whether the swimming pool is in ground or above ground."
  validates_presence_of :pool_volume, :if => :only_if_screener_pool?, :message => "Please select the volume of the swimming pool."

  validates_presence_of :cover_material, :if => :only_if_screener_cover?, :message => "Please select the material for the carport, patio cover, or porch cover."

  validates_presence_of :window_replace_glass, :if => :only_if_screener_window?, :message => "Please select whether you are only replacing broken glass or not."
  
  validates_presence_of :door_replace_existing, :if => :only_if_screener_door?, :message => "Please select whether you are only replacing doors on their existing hinges or not."
  
  validates_presence_of :wall_general_changes, :if => :only_if_screener_wall?, :message => "Please select whether you are only doing paint, wallpaper, or repairing sheetrock without moving or altering studs."
  
  validates_presence_of :siding_over_existing, :if => :only_if_screener_siding?, :message => "Please select whether you are only placing new siding over existing siding or not."
  
  validates_presence_of :floor_covering, :if => :only_if_screener_floor?, :message => "Please select whether you are only doing floor covering such as carpet, tile, wood/laminate flooring or not."

  validates_presence_of :owner_address, :if => :active_or_screener_details?, :message => "Please enter a San Antonio address."
  
  # validates on permit_steps#enter_details
  validates :owner_address, :address => true, :if => :only_if_address_presence?
  validates_presence_of :owner_name, :if => :active_or_details?, :message => "Please enter home owner name."
  validates_inclusion_of :contractor, :in => [true, false], :if => :active_or_details?, :message => "Please select whether you are using a contractor or not in this project."
  validates_presence_of :work_summary, :if => :active_or_details?, :message => "Please enter a work summary."
  validates_presence_of :job_cost, :if => :active_or_details?, :message => "Please enter the job cost."
  #validates :job_cost, :if => :only_if_job_cost_presence?, :format => { :with => /\A\d+(?:\.\d{0,2})?\z/ }, :message => "Job cost has an invalid format, it should be like 1000000.00"
  #validates :job_cost, :if => :only_if_job_cost_presence?, :numericality => {:greater_than => 0, :less_than => 1000000000000}, :message => "Job cost should be between the range of 0.00 to 1000000000000.00"
  #validates_numericality_of :job_cost, :if => :only_if_job_cost_presence?, :message => "Job cost must be a number."
  validates_format_of :job_cost, :if => :only_if_job_cost_presence?, :with => /\A\d+(?:\.\d{0,2})?\z/, :message => "Job cost has an invalid format, it should be like 1000000.00"
  validates_numericality_of :job_cost, :if => :only_if_job_cost_presence?, :greater_than => 0, :less_than => 1000000000000 , :message => "Job cost should be between the range of 0.00 to 1000000000000.00"  
  
  # validates on permit_steps#enter_addition
  validates_presence_of :house_area, :if => :active_or_details_addition?, :message => "Please enter the size of house in square feet."
  validates_numericality_of :house_area, :if => :only_if_house_presence?, :message => "Please enter the size of house in square feet."
  validates_presence_of :addition_area, :if => :active_or_details_addition?, :message => "Please enter the size of addition in square feet."
  validates_numericality_of :addition_area, :if => :only_if_addition_presence?, :message => "Please enter the size of addition in square feet."
  validates_numericality_of :addition_area, less_than: 1000, :if => :only_if_addition_presence?, :message => "Addition must be less than 1,000 Square Feet."
  validates_presence_of :ac, :if => :active_or_details_addition?, :message => "Please select an air conditioning / heating system."

  # validates on permit_steps#enter_repair
  validates_numericality_of :window_count, greater_than: 0, :if => :only_if_window_true?, :message => "Please specify the number of windows you are repairing."
  validates_numericality_of :door_count, greater_than: 0, :if=> :only_if_door_true?, :message => "Please specify the number of doors you are repairing."

  # validates on permit_step#confirm_details
  
  validates_acceptance_of :accepted_terms, :accept => true, :if => :accepted_terms_acceptance?, :message => "Please accept the terms listed here by checking the box below."
  before_save :ensure_name_confirmed, :if => :accepted_terms_acceptance?, :message => "The name didn't validate."



  def active?
    status == 'active'
  end

  def active_or_screener_details?
    status.to_s.include?('answer_screener') || 
    status.to_s.include?('enter_details') || 
    active?
  end

  def active_or_screener?
    status.to_s.include?('answer_screener') || active?
  end

  def only_if_screener_addition?
    active_or_screener? && addition
  end

  def only_if_screener_acs_struct?
    active_or_screener? && acs_struct
  end

  def only_if_screener_deck?
    active_or_screener? && deck
  end

  def only_if_screener_pool?
    active_or_screener? && pool
  end

  def only_if_screener_cover?
    active_or_screener? && cover
  end

  def only_if_screener_window?
    active_or_screener? && window
  end

  def only_if_screener_door?
    active_or_screener? && door
  end

  def only_if_screener_wall?
    active_or_screener? && wall
  end

  def only_if_screener_siding?
    active_or_screener? && siding
  end

  def only_if_screener_floor?
    active_or_screener? && floor
  end

  def only_if_address_presence?
    active_or_screener_details? && ! owner_address.blank?
  end

  def active_or_details?
    status.to_s.include?('enter_details') || active?
  end

  def active_or_details_addition?
    active_or_details? && addition
  end

  def only_if_addition_presence?
    active_or_details_addition? && ! addition_area.blank?
  end

  def only_if_house_presence?
    active_or_details_addition? && ! house_area.blank?
  end

  def only_if_job_cost_presence?
    active_or_details? && ! job_cost.blank?
  end

  def only_if_window_true?
    active_or_details? && window
  end

  def only_if_door_true?
    active_or_details? && door
  end

  def ensure_name_confirmed
    if !confirmed_name.eql?(owner_name)
      errors[:confirmed_name] << ("The name you entered did not match the name you used on your permit application (#{owner_name}). Please type your name again.")
    end
    confirmed_name.eql?(owner_name)
  end

  def accepted_terms_acceptance?
    status.to_s.include?('confirm_terms') || active?
  end

  def at_least_one_chosen
    if !(addition || window || door || wall || siding || floor || cover || pool || deck || acs_struct)
      errors[:base] << ("Please choose at least one project to work on.")
    end
  end
end
