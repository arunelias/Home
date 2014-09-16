class Permit < ActiveRecord::Base 
  has_many :permit_binary_details
  has_many :binaries, through: :permit_binary_details

 
  include ActiveModel::Validations
  

  ######## Virtual Attributes ########

                # User selected projects
  attr_accessor :selected_addition,
                :selected_acs_struct,
                :selected_deck,
                :selected_pool,
                :selected_cover,
                :selected_window,
                :selected_door,
                :selected_wall,
                :selected_siding,
                :selected_floor,

                #:contractor,
                
                :confirmed_name,

                # Room Addition
                :addition_size, :addition_num_story,
                # Accessory Structure
                :acs_struct_size, :acs_struct_num_story,
                # Deck
                :deck_size, :deck_grade, :deck_dwelling_attach, :deck_exit_door,
                # Pool
                :pool_location, :pool_volume,
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
  
  ######## Validations #######

  # @TODO: Should I group these in terms of each view, should model have an idea of how the views look like

  ## Validations on permit_steps#new ##

  before_validation(on: :create) do
    projects_to_bool
  end
  validate :at_least_one_chosen, :if => :first_step?

  ## Validations on permit_steps#answer_screener ##

  # Addition Section
  validates_presence_of :addition_size, :if => :only_if_screener_addition?
  validates_presence_of :addition_num_story, :if => :only_if_screener_addition?

  # Accessory Structure Section
  validates_presence_of :acs_struct_size, :if => :only_if_screener_acs_struct?
  validates_presence_of :acs_struct_num_story, :if => :only_if_screener_acs_struct?

  # Deck Section
  validates_presence_of :deck_size, :if => :only_if_screener_deck?
  validates_presence_of :deck_grade, :if => :only_if_screener_deck?
  validates_presence_of :deck_dwelling_attach, :if => :only_if_screener_deck?
  validates_presence_of :deck_exit_door, :if => :only_if_screener_deck?

  # Pool Section
  validates_presence_of :pool_location, :if => :only_if_screener_pool?
  validates_presence_of :pool_volume, :if => :only_if_screener_pool?

  # Window Section
  validates_presence_of :window_replace_glass, :if => :only_if_screener_window?
  
  # Door Section
  validates_presence_of :door_replace_existing, :if => :only_if_screener_door?
  
  # Wall Section
  validates_presence_of :wall_general_changes, :if => :only_if_screener_wall?
  
  # Siding Section
  validates_presence_of :siding_over_existing, :if => :only_if_screener_siding?
  
  # Floor Section
  validates_presence_of :floor_covering, :if => :only_if_screener_floor?

  # Contractor Section
  validates_inclusion_of :contractor, :in => [true, false], :if => :active_or_screener?

  # Home Address Section
  validates_presence_of :owner_address, :if => :active_or_screener_details?
  validates_with AddressValidator, :if => :only_if_address_presence?
  
  ## Validations on permit_steps#enter_details ##

  # Basic Information Section
  validates_presence_of :owner_name, :if => :active_or_details?
  # Validator for owner_address above at permit_steps#answer_screener
  validates_format_of :email, :if => :active_or_details?, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_format_of :phone, :if => :active_or_details?, :with => /\A(\+0?1\s)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}\z/i

  # Addition Section
  validates_presence_of :house_area, :if => :active_or_details_addition?
  validates_numericality_of :house_area, :if => :only_if_house_presence?
  validates_presence_of :addition_area, :if => :active_or_details_addition?
  validates_numericality_of :addition_area, :if => :only_if_addition_presence?
  validates_numericality_of :addition_area, less_than: 1000, :if => :only_if_addition_presence?
  validates_presence_of :ac, :if => :active_or_details_addition?

  # Window Section
  validates_numericality_of :window_count, greater_than: 0, :if => :only_if_window_true?
  
  # Door Section
  validates_numericality_of :door_count, greater_than: 0, :if=> :only_if_door_true?

  # Final Info Section
  validates_presence_of :work_summary, :if => :active_or_details?
  validates_presence_of :job_cost, :if => :active_or_details?
  validates_format_of :job_cost, :if => :only_if_job_cost_presence?, :with => /\A\d+(?:\.\d{0,2})?\z/
  validates_numericality_of :job_cost, :if => :only_if_job_cost_presence?, :greater_than => 0, :less_than => 1000000000000
  ## Validations on permit_step#confirm_terms ##

  validates_acceptance_of :accepted_terms, :accept => true, :if => :accepted_terms_acceptance?
  before_save :ensure_name_confirmed, :if => :accepted_terms_acceptance?, :message => I18n.t('models.permit.ensure_name_confirmed_msg')
  # @TODO: may want to do this instead of before_save
  # class Person < ActiveRecord::Base
  #   validates :email, confirmation: true
  #   validates :email_confirmation, presence: true
  # end
  ######## Attribute Options Hashes ########

  # Projects
  def addition_details
    { :addition_size => { label:    I18n.t('models.permit.addition.size.label'), 
                          options:  [ { value: 'lessThan1000', label: I18n.t('models.permit.addition.size.options.lt_1000') }, 
                                      { value: 'greaterThanEqualTo1000',  label: I18n.t('models.permit.addition.size.options.gte_1000')}]},
      :addition_num_story =>  { label:    I18n.t('models.permit.addition.num_story.label'),
                                options:  [ { value: '1Story', label: I18n.t('models.permit.addition.num_story.options.one') }, 
                                            { value: '2orMoreStories', label: I18n.t('models.permit.addition.num_story.options.two_or_more') }]}}
  end

  def acs_struct_details
    { :acs_struct_size =>  {  label:    I18n.t('models.permit.acs_struct.size.label'),
                              options:  [ { value: 'lessThanEqualTo120', label: I18n.t('models.permit.acs_struct.size.options.lte_120') }, 
                                          { value: 'greaterThan120', label: I18n.t('models.permit.acs_struct.size.options.gt_120') }]},
      :acs_struct_num_story => {  label:     I18n.t('models.permit.acs_struct.num_story.label'),
                                  options:  [ { value: '1Story', label: I18n.t('models.permit.acs_struct.num_story.options.one') }, 
                                              { value: '2orMoreStories', label: I18n.t('models.permit.acs_struct.num_story.options.two_or_more') }]}}

  end

  def deck_details
    { :deck_size => { label:    I18n.t('models.permit.deck.size.label'),
                      options:  [ { value: 'lessThanEqualTo200', label: I18n.t('models.permit.deck.size.options.lte_200') },
                                  { value: 'greaterThan200', label: I18n.t('models.permit.deck.size.options.gt_200') }]},
      :deck_grade => {  label:    I18n.t('models.permit.deck.grade.label'),
                        options:  [ { value: 'lessThanEqualTo30', label: I18n.t('models.permit.deck.grade.options.lte_30')},
                                    { value: 'moreThan30', label: I18n.t('models.permit.deck.grade.options.gt_30')}]},
      :deck_dwelling_attach => {  label:    I18n.t('models.permit.deck.dwelling_attach.label'),
                                  options:  [ { value: 'attachedToDwelling', label: I18n.t('models.permit.deck.dwelling_attach.options.attached')},
                                              { value: 'notAttachedToDwelling', label: I18n.t('models.permit.deck.dwelling_attach.options.not_attached')}]},
      :deck_exit_door => {  label:    I18n.t('models.permit.deck.exit_door.label'),
                            options:  [ { value: 'exitDoor', label: I18n.t('models.permit.deck.exit_door.options.served')},
                                        { value: 'noExitDoor', label: I18n.t('models.permit.deck.exit_door.options.not_served')}]}}
  end

  def pool_details
    { :pool_location => { label:    I18n.t('models.permit.pool.location.label'),
                          options:  [ { value: 'inGround', label: I18n.t('models.permit.pool.location.options.in_ground')}, 
                                      { value: 'aboveGround', label: I18n.t('models.permit.pool.location.options.above_ground') }]},
      :pool_volume => { label:    I18n.t('models.permit.pool.volume.label'),
                        options:  [ { value: 'lessThanEqualTo5000', label: I18n.t('models.permit.pool.volume.options.lte_5000')}, 
                                    { value: 'moreThan5000', label: I18n.t('models.permit.pool.volume.options.gt_5000')}]}}
  end

  # Room Addition
  def ac_options
    [I18n.t('models.permit.ac.options.none'), I18n.t('models.permit.ac.options.wall'), I18n.t('models.permit.ac.options.extended'), I18n.t('models.permit.ac.options.split')]
  end

  ######## Conditions for Validation ########
  def first_step?
    status == nil
  end

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
    status.to_s.include?('answer_screener') && to_bool(selected_addition)
  end

  def only_if_screener_acs_struct?
    status.to_s.include?('answer_screener') && to_bool(selected_acs_struct)
  end

  def only_if_screener_deck?
    status.to_s.include?('answer_screener') && to_bool(selected_deck)
  end

  def only_if_screener_pool?
    status.to_s.include?('answer_screener') && to_bool(selected_pool)
  end

  def only_if_screener_cover?
    status.to_s.include?('answer_screener') && to_bool(selected_cover)
  end

  def only_if_screener_window?
    status.to_s.include?('answer_screener') && to_bool(selected_window)
  end

  def only_if_screener_door?
    status.to_s.include?('answer_screener') && to_bool(selected_door)
  end

  def only_if_screener_wall?
    status.to_s.include?('answer_screener') && to_bool(selected_wall)
  end

  def only_if_screener_siding?
    status.to_s.include?('answer_screener') && to_bool(selected_siding)
  end

  def only_if_screener_floor?
    status.to_s.include?('answer_screener') && to_bool(selected_floor)
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
      errors[:confirmed_name] << (I18n.t('models.permit.confirmed_name_msg', name: owner_name))
    end
    confirmed_name.eql?(owner_name)
  end

  def accepted_terms_acceptance?
    status.to_s.include?('confirm_terms') || active?
  end

  def at_least_one_chosen
    if !( to_bool(selected_addition) || to_bool(selected_window) || to_bool(selected_door) || 
          to_bool(selected_wall) || to_bool(selected_siding) || to_bool(selected_floor) || 
          to_bool(selected_cover) || to_bool(selected_pool) || to_bool(selected_deck) || 
          to_bool(selected_acs_struct))

      errors[:base] << (I18n.t('models.permit.no_proj_chosen_msg'))
    end
  end

  
  ########  Business Logic for when Permit is needed ########

  # Return true if this permit is needed, false if not needed, nil if more guidance will be needed from DSD
  def addition_permit_needed?
    if addition_size.eql?("lessThan1000") && addition_num_story.eql?("1Story")
      return true
    else
      return nil
    end
  end

  def acs_struct_permit_needed?
    if acs_struct_size.eql?('greaterThan120') && acs_struct_num_story.eql?('1Story')
      return true
    elsif acs_struct_size.eql?('lessThanEqualTo120') && acs_struct_num_story.eql?('1Story')
      return false
    else
      return nil
    end
  end

  def deck_permit_needed?
    if  deck_size.eql?('lessThanEqualTo200') && 
        deck_grade.eql?('lessThanEqualTo30') && 
        deck_dwelling_attach.eql?('notAttachedToDwelling') && 
        deck_exit_door.eql?('noExitDoor')
      return false
    else
      return true
    end
  end

  def pool_permit_needed?
    if pool_location.eql?('inGround')
      return true
    elsif pool_location.eql?('aboveGround') && pool_volume.eql?('moreThan5000')
      return true
    elsif pool_location.eql?('aboveGround') && pool_volume.eql?('lessThanEqualTo5000')
      return false
    else
      return nil
    end
  end

  def cover_permit_needed?
    return true
  end

  def window_permit_needed?
    if to_bool(window_replace_glass)
      return false
    else
      return true
    end
  end

  def door_permit_needed?
    if to_bool(door_replace_existing)
      return false
    else
      return true
    end
  end

  def wall_permit_needed?
    if to_bool(wall_general_changes)
      return false
    else
      return true
    end
  end

  def siding_permit_needed?
    if to_bool(siding_over_existing)
      return false
    else
      return true
    end
  end

  def floor_permit_needed?
    if to_bool(floor_covering)
      return false
    else
      return true
    end
  end

  def update_permit_needs_for_projects
    permit_needs = { "permit_needed" => [], "permit_not_needed" => [], "further_assistance_needed" => [] }

    if to_bool(selected_addition) 

      if addition_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.addition.name'))
        update_attribute("addition", true)
      else
        permit_needs["further_assistance_needed"].push(I18n.t('models.permit.addition.name'))
        update_attribute("addition", nil)
      end

    end

    ####### Helpers Methods to change virtual attributes values to booleans ########
    # @TODO: Check if these are necessary anymore

    if to_bool(selected_acs_struct)

      if acs_struct_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.acs_struct.name'))
        update_attribute("acs_struct", true)
      elsif acs_struct_permit_needed? == false
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.acs_struct.name'))
      else
        permit_needs["further_assistance_needed"].push(I18n.t('models.permit.acs_struct.name'))
        update_attribute("acs_struct", nil)
      end

    end

    if to_bool(selected_deck)

      if deck_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.deck.name'))
        update_attribute("deck", true)
      elsif deck_permit_needed? == false
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.deck.name'))
      else
        permit_needs["further_assistance_needed"].push(I18n.t('models.permit.deck.name'))
        update_attribute("deck", nil)
      end

    end

    if to_bool(selected_pool)

      if pool_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.pool.name'))
        update_attribute("pool", true)
      elsif pool_permit_needed? == false
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.pool.name'))
        update_attribute("pool", false)
      else
        permit_needs["further_assistance_needed"].push(I18n.t('models.permit.pool.name'))
        update_attribute("pool", nil)
      end

    end

    if to_bool(selected_cover)

      if cover_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.cover.name'))
        update_attribute("cover", true)
      else
        permit_needs["further_assistance_needed"].push(I18n.t('models.permit.cover.name'))
        update_attribute("cover", nil)
      end

    end

    if to_bool(selected_window)

      if window_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.window.name'))
        update_attribute("window", true)
      else
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.window.name'))
        update_attribute("window", false)
      end

    end

    if to_bool(selected_door)
      if door_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.door.name'))
        update_attribute("door", true)
      else
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.door.name'))
        update_attribute("door", false)
      end

    end

    if to_bool(selected_wall)
      if wall_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.wall.name'))
        update_attribute("wall", true)
      else
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.wall.name'))
        update_attribute("wall", false)
      end

    end

    if to_bool(selected_siding)

      if siding_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.siding.name'))
        update_attribute("siding", true)
      else
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.siding.name'))
        update_attribute("siding", false)
      end

    end

    if to_bool(selected_floor)
      if floor_permit_needed?
        permit_needs["permit_needed"].push(I18n.t('models.permit.floor.name'))
        update_attribute("floor", true)
      else
        permit_needs["permit_not_needed"].push(I18n.t('models.permit.floor.name'))
        update_attribute("floor", false)
      end

    end


    return permit_needs
  end

  def to_bool(value)
    if value == "1" || value == 1 || value == true || value == "true"
      return true
    else
      return false
    end
  end
    
  def projects_to_bool
    selected_addition = to_bool(selected_addition)
    selected_acs_struct = to_bool(selected_acs_struct)
    selected_deck = to_bool(selected_deck)
    selected_pool = to_bool(selected_pool)
    selected_cover = to_bool(selected_cover)
    selected_window = to_bool(selected_window)
    selected_door = to_bool(selected_door)
    selected_wall = to_bool(selected_wall)
    selected_siding = to_bool(selected_siding)
    selected_floor = to_bool(selected_floor)

    return nil
  end


end
