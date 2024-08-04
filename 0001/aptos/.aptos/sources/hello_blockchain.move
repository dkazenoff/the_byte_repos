module hello_blockchain::message {
    use std::error;      // Import standard error handling utilities
    use std::signer;     // Import functionalities related to signers (e.g., for accounts)
    use std::string;     // Import string utilities
    use aptos_framework::event;  // Import event handling from the Aptos framework

    // Define a resource type `MessageHolder` that will hold a message
    // `has key` indicates this resource type can be stored with a unique key (e.g., for accounts)
    // This is important for ensuring the uniqueness and accessibility of each `MessageHolder`
    // The `resource` keyword is used to define a resource in Move, which ensures it can be securely stored and manipulated
    // `MessageHolder` will be stored in a global context identified by its key (e.g., an account address)
    // The resource has a single field: `message` of type `string::String`
    // This represents the message associated with an account
    // `MessageHolder` has the `key` capability, meaning it can be uniquely identified and manipulated
    // Resources are managed in a way that ensures they are properly accounted for and accessed securely
    // The key allows for efficient retrieval and updates
    // `has key` allows for creating, moving, and deleting instances of this resource
    // The `message` field holds the actual text string
    struct MessageHolder has key {
        message: string::String,
    }

    // Define an event `MessageChange` that tracks changes to messages
    // `has drop, store` indicates this event can be stored and logged, and can be used for auditing or tracking
    // This event captures the account address, the previous message, and the new message
    // The `event` keyword is used to define events that will be emitted during execution
    // Events are useful for tracking state changes and interacting with external systems
    #[event]
    struct MessageChange has drop, store {
        account: address,           // Address of the account whose message was changed
        from_message: string::String, // The message that was replaced
        to_message: string::String,   // The new message
    }

    // Define a constant `ENO_MESSAGE` representing an error code for "no message found"
    // Constants are useful for defining fixed values that are used throughout the module
    // This constant is used in error handling to indicate when a message does not exist
    const ENO_MESSAGE: u64 = 0;

    // Define a view function `get_message` to retrieve a message associated with an address
    // `acquires MessageHolder` indicates that this function requires access to the `MessageHolder` resource
    // This ensures the function can read the state of the `MessageHolder` if it exists
    // `assert!` checks if the `MessageHolder` resource exists for the given address
    // If not, an error is returned using `error::not_found`
    // The function returns the current message stored in `MessageHolder` for the given address
    #[view]
    public fun get_message(addr: address): string::String acquires MessageHolder {
        assert!(exists<MessageHolder>(addr), error::not_found(ENO_MESSAGE));
        borrow_global<MessageHolder>(addr).message
    }

    // Define an entry function `set_message` to set a message for a given account
    // `acquires MessageHolder` means this function needs access to `MessageHolder`
    // `signer` indicates the function is called by an account that can sign transactions
    // `move_to` is used to create a new `MessageHolder` if one does not exist for the address
    // If a `MessageHolder` already exists, it retrieves the current message, emits a `MessageChange` event,
    // and updates the message to the new value
    // `event::emit` is used to log the change for transparency and tracking
    public entry fun set_message(account: signer, message: string::String)
    acquires MessageHolder {
        let account_addr = signer::address_of(&account);
        if (!exists<MessageHolder>(account_addr)) {
            move_to(&account, MessageHolder {
                message,
            })
        } else {
            let old_message_holder = borrow_global_mut<MessageHolder>(account_addr);
            let from_message = old_message_holder.message;
            event::emit(MessageChange {
                account: account_addr,
                from_message,
                to_message: copy message,
            });
            old_message_holder.message = message;
        }
    }

    // Define a test function `sender_can_set_message` to verify that an account can set a message
    // `acquires MessageHolder` means the test needs access to `MessageHolder`
    // `aptos_framework::account::create_account_for_test` is used to create a test account
    // `set_message` is called to set a test message
    // `assert!` checks if the message was set correctly by comparing it to the expected value
    #[test(account = @0x1)]
    public entry fun sender_can_set_message(account: signer) acquires MessageHolder {
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        set_message(account, string::utf8(b"Hello Aptos! From The Byte"));

        assert!(
            get_message(addr) == string::utf8(b"Hello Aptos! From The Byte"),
            ENO_MESSAGE
        );
    }
}
