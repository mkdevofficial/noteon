const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "note-on-mkdevofficial";

describe("NoteOn Firestore Security Rules", () => {
  let testEnv;

  before(async () => {
    const rulesPath = path.resolve(__dirname, "../../firestore.rules");
    const rules = fs.readFileSync(rulesPath, "utf8");

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules,
        host: "127.0.0.1",
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
    }
  });

  // --- Users Collection Tests ---
  describe("users/{uid}", () => {
    it("allows a user to read and write their own profile", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      const aliceDoc = aliceContext.firestore().collection("users").doc("alice");

      await assertSucceeds(
        aliceDoc.set({
          uid: "alice",
          displayName: "Alice",
          email: "alice@example.com",
        })
      );

      await assertSucceeds(aliceDoc.get());
    });

    it("denies a user from reading or writing another user's profile", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      const bobDoc = aliceContext.firestore().collection("users").doc("bob");

      await assertFails(
        bobDoc.set({
          uid: "bob",
          displayName: "Hacked",
        })
      );

      await assertFails(bobDoc.get());
    });
  });

  // --- UserDirectory Tests ---
  describe("userDirectory/{emailHash}", () => {
    it("allows user to write their own email hash", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      const hashDoc = aliceContext.firestore().collection("userDirectory").doc("alice_hash");

      await assertSucceeds(
        hashDoc.set({
          uid: "alice",
        })
      );
    });

    it("denies user from writing another user's uid in hash doc", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      const hashDoc = aliceContext.firestore().collection("userDirectory").doc("bob_hash");

      await assertFails(
        hashDoc.set({
          uid: "bob",
        })
      );
    });

    it("denies collection listing of userDirectory", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      await assertFails(aliceContext.firestore().collection("userDirectory").get());
    });
  });

  // --- Notes Collection Tests ---
  describe("notes/{noteId}", () => {
    it("allows owner to create note when valid fields are provided", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      const noteRef = aliceContext.firestore().collection("notes").doc("note1");

      await assertSucceeds(
        noteRef.set({
          ownerId: "alice",
          memberIds: ["alice"],
          roles: { alice: "owner" },
          type: "text",
          title: "My Secret Note",
          plainText: "Hello world",
          order: 0,
        })
      );
    });

    it("denies creating note where title exceeds 500 characters", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      const noteRef = aliceContext.firestore().collection("notes").doc("note_long");

      await assertFails(
        noteRef.set({
          ownerId: "alice",
          memberIds: ["alice"],
          roles: { alice: "owner" },
          title: "A".repeat(501),
        })
      );
    });

    it("allows note member to read, denies non-member", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("notes").doc("note_shared").set({
          ownerId: "alice",
          memberIds: ["alice", "bob"],
          roles: { alice: "owner", bob: "viewer" },
          title: "Shared Note",
        });
      });

      const bobContext = testEnv.authenticatedContext("bob");
      const charlieContext = testEnv.authenticatedContext("charlie");

      await assertSucceeds(
        bobContext.firestore().collection("notes").doc("note_shared").get()
      );

      await assertFails(
        charlieContext.firestore().collection("notes").doc("note_shared").get()
      );
    });

    it("allows editor to update note content but denies non-owner from changing roles", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("notes").doc("note_collab").set({
          ownerId: "alice",
          memberIds: ["alice", "bob"],
          roles: { alice: "owner", bob: "editor" },
          title: "Collaboration Document",
          plainText: "Initial",
        });
      });

      const bobContext = testEnv.authenticatedContext("bob");
      const noteRef = bobContext.firestore().collection("notes").doc("note_collab");

      // Bob updates content -> allowed
      await assertSucceeds(
        noteRef.update({
          title: "Updated by Bob",
          plainText: "New content",
        })
      );

      // Bob tries to elevate himself to owner -> denied
      await assertFails(
        noteRef.update({
          roles: { alice: "editor", bob: "owner" },
        })
      );
    });

    it("allows only owner to delete note", async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("notes").doc("note_del").set({
          ownerId: "alice",
          memberIds: ["alice", "bob"],
          roles: { alice: "owner", bob: "editor" },
          title: "To Be Deleted",
        });
      });

      const bobContext = testEnv.authenticatedContext("bob");
      const aliceContext = testEnv.authenticatedContext("alice");

      // Bob cannot delete
      await assertFails(
        bobContext.firestore().collection("notes").doc("note_del").delete()
      );

      // Alice can delete
      await assertSucceeds(
        aliceContext.firestore().collection("notes").doc("note_del").delete()
      );
    });
  });

  // --- Tasks Collection Tests ---
  describe("tasks/{taskId}", () => {
    it("allows owner to create task and member to read", async () => {
      const aliceContext = testEnv.authenticatedContext("alice");
      const taskRef = aliceContext.firestore().collection("tasks").doc("task1");

      await assertSucceeds(
        taskRef.set({
          ownerId: "alice",
          memberIds: ["alice"],
          roles: { alice: "owner" },
          title: "Call Ahmed",
          status: "todo",
          priority: "high",
        })
      );

      await assertSucceeds(taskRef.get());
    });

    it("denies unauthenticated read/write to tasks", async () => {
      const unauth = testEnv.unauthenticatedContext();
      await assertFails(
        unauth.firestore().collection("tasks").doc("task1").get()
      );
    });
  });
});
