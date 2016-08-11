defmodule FinTex.User.FinAccount do
  @moduledoc """
  The following fields are public:
    * `account_number`          - Account number
    * `subaccount_id`           - Subaccount ID
    * `blz`                     - Bank code
    * `bank_name`               - Bank name
    * `currency`                - Three-character currency code (ISO 4217)
    * `iban`                    - IBAN
    * `bic`                     - BIC
    * `name`                    - Account name
    * `owner`                   - Name of the account holder
    * `type`                    - Account type. Possible values are `:giro_account`, `:savings_account`,
                                  `:credit_card` or `:loan_account`, `:cash_book`, `:depot` or `:unknown`.
    * `balance`                 - Account balance
    * `supported_payments`      - List of payment types with payment parameters
    * `supported_transactions`  - List of transaction names
    * `supported_tan_schemes`   - List of TAN schemes
    * `preferred_tan_scheme`    - Security function of the TAN scheme preferred by the user
  """

  alias FinTex.Model.Account
  alias FinTex.Model.Balance
  alias FinTex.Model.TANScheme

  @type t :: %__MODULE__{
    type: Atom.t,
    account_number: String.t,
    subaccount_id: String.t,
    blz: String.t,
    bank_name: String.t,
    currency: String.t,
    iban: String.t,
    bic: String.t,
    name: String.t,
    owner: String.t,
    balance: Balance.t,
    supported_payments: map,
    supported_tan_schemes: [TANScheme.t],
    preferred_tan_scheme: String.t,
    supported_transactions: [String.t]
  }

  defstruct [
    :account_number,
    :subaccount_id,
    :blz,
    :bank_name,
    :currency,
    :iban,
    :bic,
    :name,
    :owner,
    type: :unknown,
    balance: nil,
    supported_payments: Map.new,
    supported_tan_schemes: [],
    preferred_tan_scheme: nil,
    supported_transactions: []
  ]

  use Vex.Struct

  validates :blz, blz: [allow_nil: true]

  validates :iban, presence: [if: :bic], iban: [if: :bic]

  validates :bic, presence: [if: :iban], bic: [if: :iban]

  validates :owner, presence: true, length: [in: 1..140]

  @doc false
  @spec from_account(Account.t) :: t
  def from_account(account) do
    %__MODULE__{
      account_number:         account |> Account.account_number,
      subaccount_id:          account |> Account.subaccount_id,
      blz:                    account |> Account.blz,
      iban:                   account |> Account.iban,
      bic:                    account |> Account.bic,
      owner:                  account |> Account.owner
    }
  end


  def key(%__MODULE__{
    account_number: account_number,
    subaccount_id: subaccount_id
  }) do
    "#{account_number}#{subaccount_id}"
  end
end


defimpl FinTex.Model.Account, for: [FinTex.User.FinAccount, Map] do

  def account_number(account) do
    account |> Map.get(:account_number)
  end

  def subaccount_id(account) do
    account |> Map.get(:subaccount_id)
  end

  def blz(account) do
    account |> Map.get(:blz)
  end

  def iban(account) do
    account |> Map.get(:iban)
  end

  def bic(account) do
    account |> Map.get(:bic)
  end

  def owner(account) do
    account |> Map.get(:owner)
  end
end


defimpl FinTex.Model.Account, for: List do

  def account_number(account) do
    account |> Keyword.get(:account_number)
  end

  def subaccount_id(account) do
    account |> Keyword.get(:subaccount_id)
  end

  def blz(account) do
    account |> Keyword.get(:blz)
  end

  def iban(account) do
    account |> Keyword.get(:iban)
  end

  def bic(account) do
    account |> Keyword.get(:bic)
  end

  def owner(account) do
    account |> Keyword.get(:owner)
  end
end
