defmodule ExUtils.GlobalPresence do
  use Phoenix.Presence, otp_app: :ex_utils,
                        pubsub_server: ExUtils.GlobalPresence.PubSub
end
