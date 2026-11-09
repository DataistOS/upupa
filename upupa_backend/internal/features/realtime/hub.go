package realtime

import (
	"encoding/json"
	"sync"
)

type Client struct {
	ID     string
	Send   chan []byte
	Topics map[string]bool
}

type SSEHub struct {
	clients    map[*Client]bool
	register   chan *Client
	unregister chan *Client
	broadcast  chan Message
	mutex      sync.RWMutex
}

type Message struct {
	Event   string      `json:"event"`
	Channel string      `json:"channel"`
	Data    interface{} `json:"data"`
}

func NewSSEHub() *SSEHub {
	hub := &SSEHub{
		clients:    make(map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan Message),
	}
	go hub.run()
	return hub
}

func (h *SSEHub) run() {
	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client] = true
			h.mutex.Unlock()

		case client := <-h.unregister:
			h.mutex.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.Send)
			}
			h.mutex.Unlock()

		case message := <-h.broadcast:
			h.mutex.RLock()
			payload, err := json.Marshal(message)
			if err != nil {
				h.mutex.RUnlock()
				continue
			}

			for client := range h.clients {
				select {
				case client.Send <- payload:
				default:
					close(client.Send)
					delete(h.clients, client)
				}
			}
			h.mutex.RUnlock()
		}
	}
}

func (h *SSEHub) Broadcast(event string, channel string, data interface{}) {
	h.broadcast <- Message{
		Event:   event,
		Channel: channel,
		Data:    data,
	}
}

var GlobalHub = NewSSEHub()