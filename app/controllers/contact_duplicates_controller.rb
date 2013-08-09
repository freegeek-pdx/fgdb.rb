class ContactDuplicatesController < ApplicationController
  layout :with_sidebar
  protected
  public

  def index
  end

  def show_dups
    if params[:ids]
      @contacts = params[:ids]
    elsif params[:dup_check]
      @contacts = ContactDuplicate.find_all_by_dup_check(params[:dup_check]).map(&:contact)
    elsif params[:list]
      @contacts = params[:list].split(" ").collect{|x| x.split(",")}.flatten.collect{|x| x.to_i}
    else
      @contacts = []
    end
    @contacts.collect!{|x| Contact.find_by_id(x)}.delete_if{|x| x.nil?}
  end

  def combine_dups
    keepers = params["ids"].to_a.select{|x| x[1]["keeper"]}.map{|x| x[0].to_i}
    mergers = params["ids"].to_a.select{|x| x[1]["merge"]}.map{|x| x[0].to_i}
    if keepers.length != 1
      @error = "You must choose 1 keeper"
      return
    end
    if (keepers & mergers).length != 0
      @error = "A keeper cannot also be merged"
      return
    end
    if mergers.length == 0
      @error = "You must choose at least 1 record to be merged"
      return
    end
    @keeper = Contact.find_by_id(keepers[0])
    if !@keeper
      @error = "The keeper doesn't exist"
      return
    end
    oops = false
    @mergers = mergers.map{|x| Contact.find_by_id(x) || oops = true}
    if oops
      @error = "One of the to be merged records does not exist"
      return
    end
    @keeper.merge_these_in(@mergers)
  end

  def list_dups
    @duplicates = ContactDuplicate.list_dups().paginate(:page => params[:page])
  end
end
