class BankAccount < ApplicationRecord
  has_many :bank_transactions, dependent: :destroy
  has_many :supplier_categories, dependent: :nullify
  belongs_to :bank_gateway, optional: true

  normalize_attributes :name, :iban, :description

  validates :name, presence: true, uniqueness: true, length: { minimum: 2 }
  validates :iban, presence: true, uniqueness: true
  validates :iban, format: { with: /\A[A-Z]{2}[0-9]{2}[0-9A-Z]{,30}\z/ }
  validates :balance, numericality: { message: I18n.t('bank_account.model.invalid_balance') }

  # @return [Function] Method wich can be called to import transaction from a bank or nil if unsupported
  def find_connector
    klass = BankAccountConnector.find iban
    return klass.new self if klass
  end

  def assign_unlinked_transactions
    count = 0
    bank_transactions.without_financial_link.includes(:supplier, :user).find_each do |t|
      count += 1 if t.assign_to_ordergroup || t.assign_to_invoice
    end
    count
  end

  def last_transaction_date
    bank_transactions.order(date: :desc).first&.date
  end
end
