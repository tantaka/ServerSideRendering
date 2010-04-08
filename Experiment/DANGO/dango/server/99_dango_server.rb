# -*- coding: utf-8 -*-
=begin
= dangoサーバー
=end

class DangoServer < DangoServerFramework
  # サーバー起動時のインスタンス変数などを定義するメソッド
  # ここで定義されるインスタンス変数はサーバー全体で共有される
  def dango_server_init()
    shared[:users] = []
  end

  # クライアント接続時に呼び出されるメソッド
  def dango_connect()
    shared.transaction(:users) do |users|
      users.push(session[:sid])
      shared.commit(users)
    end
  end

  # クライアント接続解除時に呼び出されるメソッド
  def dango_close()
    shared.transaction(:users) do |users|
      users.delete(session[:sid])
      shared.commit(users)
    end
  end

  # メッセージを受信して、全員に送信
  def dango_receive_send_message(rec_obj)
    send_obj = {:message => rec_obj["message"]}
    send_notice(:notice_message, shared[:users], send_obj)
  end
end
