module HasLinkedOwners
  extend ActiveSupport::Concern

  # POST @item./:id/owners
  def link_owners
    if params[:owners].present?
      return link_multiple_owners
    else
      return link_single_owner
    end
  end

  # GET @item./:id/owners
  def get_linked_owners
    render status: :ok, json: @item.owners_to_hash
  end

  # DELETE @item./:id/owners
  def unlink_owners
    if params[:owners].present?
      return unlink_multiple_owners
    else
      return unlink_single_owner
    end
  end

  private

  def link_single_owner
    find_owner

    result = @item.link_owner(@owner)

    if result
      head 201
    else
      head :unprocessable_entity
    end
  end

  def link_multiple_owners
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        owner_ids = params[:owners]
        one_created = false
        owner_ids.each do |owner_config|
          params[:owner_id] = owner_config[:owner_id]
          params[:owner_type] = owner_config[:owner_type]

          find_owner

          created = @item.link_owner(@owner)
          one_created = one_created || created
        end
        if one_created
          head 201
        else
          head :unprocessable_entity
        end
      end
    rescue
      head :unprocessable_entity
    end
  end

  def unlink_single_owner
    find_owner

    unless @item_owners.where(owner: @owner).exists?
      head :not_found
      return
    end

    result = @item.unlink_owner(@owner)

    if result == true
      head 200
    else
      head :unprocessable_entity
    end
  end

  def unlink_multiple_owners
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        owner_ids = params[:owners]
        one_removed = false
        owner_ids.each do |owner_config|
          params[:owner_id] = owner_config[:owner_id]
          params[:owner_type] = owner_config[:owner_type]

          find_owner

          removed = @item.unlink_owner(@owner)
          one_removed = one_removed || removed
        end
        if one_removed
          head 200
        else
          head :unprocessable_entity
        end
      end
    rescue
      head :unprocessable_entity
    end
  end

  def find_owner
    @owner =
      case params[:owner_type]
      when 'orgas'
        Orga.find(params[:owner_id])
      when 'events'
        Event.find(params[:owner_id])
      when 'offers'
        DataModules::Offer::Offer.find(params[:owner_id])
      end
    unless @owner
      raise ActiveRecord::RecordNotFound,
        "Element mit ID #{params[:owner_id]} konnte für Typ #{params[:owner_type]} nicht gefunden werden."
    end
  end

end
