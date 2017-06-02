module StateMachine

  extend ActiveSupport::Concern

  ACTIVE = :active
  INACTIVE = :inactive
  DELETED = :deleted
  STATES = [INACTIVE, ACTIVE, DELETED]
  UNDELETEDS = STATES - [DELETED]

  included do
    include AASM

    aasm(column: :state) do
      state INACTIVE, initial: true
      state *(STATES - [INACTIVE])

      event :activate do
        transitions from: INACTIVE, to: ACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :deactivate do
        transitions from: ACTIVE, to: INACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :delete do
        transitions from: UNDELETEDS, to: DELETED
        after do
          touch :state_changed_at
        end
      end

      event :restore do
        transitions from: DELETED, to: INACTIVE
        after do
          touch :state_changed_at
        end
      end
    end

    attr_writer :active

    before_create do
      self.state_changed_at = created_at
    end

    before_validation do
      if !inactive? && @active.to_s == 'false'
        skip_all_validations!
      end
    end

    before_save do
      if !active? && @active.to_s == 'true'
        activate!
      elsif !inactive? && @active.to_s == 'false'
        deactivate!
      end
    end

    # actually we decited to hard destroy, see #38:
    # soft destroyable
    scope :undeleted, -> { where(state: UNDELETEDS) }
    # def destroy
    #   run_callbacks(:destroy) do
    #     delete!
    #   end
    # end

    # def restore
    #   run_callbacks(:restore) do
    #     restore!
    #   end
    # end

    def active
      active?
    end

    def do_not_skip_all_validations!
      @skip_all_validations = false
    end

    def skip_all_validations!
      @skip_all_validations = true
    end

    def skip_all_validations?
      @skip_all_validations || false
    end
  end

end
