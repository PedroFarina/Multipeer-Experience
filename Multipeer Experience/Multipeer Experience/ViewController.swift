//
//  ViewController.swift
//  Multipeer Experience
//
//  Created by Pedro Giuliano Farina on 12/02/20.
//  Copyright © 2020 Pedro Giuliano Farina. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    @IBOutlet weak var lblReceivedMessage: UILabel!
    @IBOutlet weak var txtMessageToSend: UITextField!
    @IBOutlet weak var lblStatus: UILabel!

    @IBAction func tapSendButton(_ sender: Any) {
        let messageToSend = "\(peerID.displayName): \(txtMessageToSend.text ?? "")\n"
        let message = messageToSend.data(using: String.Encoding.utf8, allowLossyConversion: false)

        do {
            try self.mcSession.send(message!, toPeers: self.mcSession.connectedPeers, with: .unreliable)
            txtMessageToSend.text = ""
        }
        catch {
            print("Error sending message")
        }
    }

    //Nosso peerID(normalmente nada mais é que o nome do usuário)
    var peerID: MCPeerID = MCPeerID(displayName: UIDevice.current.name)
    //Sessão de multipeering
    lazy var mcSession: MCSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    //Assistente que anunciará que estamos oferecendo um serviço com o tipo MultiExp
    lazy var advertiser: MCNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "MultiExp")
    //Assistente que procurará por serviços com o tipo MultiExp
    lazy var browser: MCNearbyServiceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "MultiExp")

    override func viewDidLoad() {
        super.viewDidLoad()
        mcSession.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.lblStatus.text = "Connectado: \(peerID.displayName)"
            case .connecting:
                self.lblStatus.text = "Connectando: \(peerID.displayName)"
            case .notConnected:
                self.lblStatus.text = "Não conectado: \(peerID.displayName)"
            @unknown default:
                self.lblStatus.text = "Não previsto"
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [unowned self] in
            //Recebemos a mensagem
            let message = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
            self.lblReceivedMessage.text = message
        }
    }

    //Não recebemos streams
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }

    //Não recebemos resources
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }

    //Não recebemos resources
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }

    //Browser encontrou alguém que oferece o serviço, o que fazer?
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        //Enviar um convite para o usuário encontrado
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
    }

    //O convite foi negado, o que fazer?
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }

    //Advertiser recebeu um convite de alguém querendo entrar na sessão
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        //true para conectar, false para recusar
        invitationHandler(true, mcSession)
    }
}
