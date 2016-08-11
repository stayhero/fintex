defmodule FinTex.Segment.HKSAL do
  @moduledoc false

  alias FinTex.Model.Dialog
  alias FinTex.Helper.Segment

  defstruct [:account, segment: nil]

  import Segment

  def new(
    %__MODULE__{
      account: %{
        iban:           iban,
        bic:            bic,
        blz:            blz,
        account_number: account_number,
        subaccount_id:  subaccount_id
      }
    },
    d = %Dialog{
      country_code: country_code
    }
  ) do

    v = max_version(d, __MODULE__)

    ktv = if v >= 7 do
      [iban, bic]
    else
      [account_number, subaccount_id, country_code, blz]
    end

    %__MODULE__{
      segment:
        [
          ["HKSAL", "?", v],
          ktv,
          "N"
        ]
    }
  end
end


defimpl Inspect, for: FinTex.Segment.HKSAL do
  use FinTex.Helper.Inspect
end
