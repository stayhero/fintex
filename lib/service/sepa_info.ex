defmodule FinTex.Service.SEPAInfo do
  @moduledoc false

  alias FinTex.Command.AbstractCommand
  alias FinTex.Command.Sequencer
  alias FinTex.Data.AccountHandler
  alias FinTex.Model.Dialog
  alias FinTex.Segment.HNHBK
  alias FinTex.Segment.HNSHK
  alias FinTex.Segment.HKSPA
  alias FinTex.Segment.HNSHA
  alias FinTex.Segment.HNHBS
  alias FinTex.Service.AbstractService
  alias FinTex.User.FinAccount

  use AbstractCommand
  use AbstractService


  def has_capability? {seq, accounts} do
    %Dialog{bpd: bpd} = seq
    |> Sequencer.dialog

    bpd
    |> Map.has_key?("HKSPA" |> control_structure_to_bpd)
    &&
    accounts
    |> Map.values
    |> Enum.any?(fn %FinAccount{supported_transactions: supported_transactions} ->
       supported_transactions |> Enum.member?("HKSPA")
    end)
  end


  def update_accounts {seq, accounts} do
    request_segments = [
      %HNHBK{},
      %HNSHK{},
      %HKSPA{},
      %HNSHA{},
      %HNHBS{}
    ]

    {:ok, response} = seq |> Sequencer.call_http(request_segments)

    acc = response[:HISPA]
    |> Enum.at(0, [])
    |> Stream.drop(1)
    |> Stream.filter(fn info -> Enum.at(info, 0) === "J" end)
    |> Enum.map(fn info ->
        account = accounts
        |> AccountHandler.find_account(%FinAccount{account_number: Enum.at(info, 3), subaccount_id: Enum.at(info, 4)})
        %FinAccount{account |
          iban: Enum.at(info, 1),
          bic:  Enum.at(info, 2)
        }
    end)
    |> AccountHandler.to_accounts_map

    {seq |> Sequencer.inc, Map.merge(accounts, acc)}
  end
end
