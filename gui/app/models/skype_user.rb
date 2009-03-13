class SkypeUser < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name      :string
    username  :string
    extension :string
    status    :string
    keywords  :string
    timestamps
  end


  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end
