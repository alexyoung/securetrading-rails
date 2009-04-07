require 'socket'
 
server = TCPServer.new 5000
 
begin
  while (session = server.accept)
    response =<<-XML

<ResponseBlock Live="TRUE" Version="3.51">
 <Response Type="AUTH">
    <OperationResponse>
     <TransactionReference>#{rand(100000)}</TransactionReference>
     <AuthCode>#{rand(100000)}</AuthCode>
     <Result>#{rand(2)}</Result>
     <Message>Hello</Message>
     <SettleStatus>#{rand(1) == 1 ? 2 : 0 }</SettleStatus>
     <SecurityResponseSecurityCode>1</SecurityResponseSecurityCode>
     <SecurityResponsePostCode>1</SecurityResponsePostCode>
     <SecurityResponseAddress>1</SecurityResponseAddress>
     <TransactionCompletedTimestamp>2007-07-01 09:12:10</TransactionCompletedTimestamp>
     <TransactionVerifier>USE_FOR_REPEAT_PAYMENTS</TransactionVerifier>
    </OperationResponse>
    <Order>
     <OrderReference>Order0001</OrderReference>
     <OrderInformation>Test Order</OrderInformation>
    </Order>
 </Response>
</ResponseBlock>

    XML
    session.print response
    session.close
  end
rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
  IO.select([serv])
  retry
end