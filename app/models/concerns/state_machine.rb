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
        before do
        end
        transitions from: INACTIVE, to: ACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :deactivate do
        before do
        end
        transitions from: ACTIVE, to: INACTIVE
        after do
          touch :state_changed_at
        end
      end

      event :delete do
        before do
        end
        transitions from: UNDELETEDS, to: DELETED
        after do
          touch :state_changed_at
        end
      end

      event :restore do
        before do
        end
        transitions from: DELETED, to: INACTIVE
        after do
          touch :state_changed_at
        end
      end
    end

    attr_accessor :active

    before_create do
      self.state_changed_at = created_at
    end

    before_save do
      if !active? && active.to_s == 'true'
        activate!
      elsif !inactive? && active.to_s == 'false'
        deactivate!
      end
    end

    # soft destroyable
    scope :undeleted, -> { where(state: UNDELETEDS) }
    # TODO: How to really destroy?
    def destroy
      run_callbacks(:destroy) do
        delete!
      end
    end

    def restore
      run_callbacks(:restore) do
        restore!
      end
    end
  end

end
