module DataPlugins::Facet::Concerns::ActsAsFacetItem
  extend ActiveSupport::Concern

  def move_owners_to_new_parent
    if changes.key?('parent_id')
      old_parent_id = changes['parent_id'][0]
      if old_parent_id
        old_parent = self.class.find(old_parent_id)
        item_owners.each do |owner_relation|
          # remove only from parent if no other sub association to that parent exists
          sub_items_with_parent = 0
          items_of_owners(owner_relation.owner).each do |item|
            if item.parent_id == old_parent_id
              sub_items_with_parent += 1
            end
          end
          if sub_items_with_parent == 0
            items_of_owners(owner_relation.owner).delete(old_parent)
          end
        end
      end

      new_parent_id = changes['parent_id'][1]
      if new_parent_id
        new_parent = self.class.find(new_parent_id)
        item_owners.each do |owner_relation|
          items_of_owners(owner_relation.owner) << new_parent
        end
      end
    end
  end

  def unlink_sub_items(owner)
    if (sub_items.count)
      sub_items.each do |sub_item|
        item_owner = item_owners(sub_item).where(owner: owner).first
        if item_owner
          item_owners(sub_item).delete(item_owner)
        end
      end
    end
  end

  def validate_parent_relation
    if parent_id
      unless self.class.exists?(parent_id)
        return errors.add(:parent_id, message_parent_nonexisting)
      end

      # cannot set parent to self
      if parent_id == id
        return errors.add(:parent_id, message_sub_of_itself)
      end

      # cannot set parent if sub_items present
      if sub_items.any?
        return errors.add(:parent_id, message_sub_cannot_be_nested)
      end

      parent = self.class.find_by_id(parent_id)

      # cannot set parent to sub_item
      if parent.parent_id
        return errors.add(:parent_id, message_item_sub_of_sub)
      end
    end
  end

end