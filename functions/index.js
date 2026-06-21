const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();

const REGION = "asia-northeast3";
const MAX_TOKENS_PER_MESSAGE = 500;

exports.notifyGroupMembersOnPostCreated = onDocumentCreated(
  {
    document: "group/{groupId}/posts/{postId}",
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (event) => {
    const { groupId, postId } = event.params;
    const post = event.data && event.data.data();
    if (!post || !post.authorId) return;

    const groupSnap = await db.collection("group").doc(groupId).get();
    if (!groupSnap.exists) {
      console.warn("Notification skipped: group not found", groupId);
      return;
    }

    const group = groupSnap.data() || {};
    const memberIds = Array.isArray(group.memberIds) ? group.memberIds : [];
    const recipientIds = memberIds.filter(
      (userId) => userId && userId !== post.authorId
    );
    if (recipientIds.length === 0) return;

    const [authorSnap, tokenEntries] = await Promise.all([
      db.collection("user").doc(post.authorId).get(),
      collectFcmTokens(recipientIds),
      markUnreadNotifications({ userIds: recipientIds, groupId }),
    ]);
    if (tokenEntries.length === 0) return;

    const author = authorSnap.exists ? authorSnap.data() || {} : {};
    const authorName =
      typeof author.name === "string" && author.name.trim()
        ? author.name.trim()
        : "친구";

    const data = stringifyMessageData({
      type: "new_post",
      groupId,
      postId,
      authorId: post.authorId,
      dayKey: post.dayKey,
      hourSlot: post.hourSlot,
      slotIndex: post.slotIndex,
    });

    for (const chunk of chunkArray(tokenEntries, MAX_TOKENS_PER_MESSAGE)) {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: chunk.map((entry) => entry.token),
        notification: {
          title: "새 슬롯 영상이 도착했어요",
          body: `${authorName}님이 새로운 슬롯을 등록했어요!`,
        },
        data,
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      await deleteInvalidTokens(chunk, response.responses);
    }
  }
);

async function collectFcmTokens(userIds) {
  const tokenEntryLists = await Promise.all(
    userIds.map(async (userId) => {
      const snapshot = await db
        .collection("user")
        .doc(userId)
        .collection("fcmTokens")
        .get();

      return snapshot.docs
        .map((doc) => ({
          token: String(doc.data().token || doc.id),
          ref: doc.ref,
        }))
        .filter((entry) => entry.token);
    })
  );

  const uniqueEntriesByToken = new Map();
  for (const entry of tokenEntryLists.flat()) {
    if (!uniqueEntriesByToken.has(entry.token)) {
      uniqueEntriesByToken.set(entry.token, entry);
    }
  }
  return [...uniqueEntriesByToken.values()];
}

async function markUnreadNotifications({ userIds, groupId }) {
  const batch = db.batch();
  const timestamp = admin.firestore.FieldValue.serverTimestamp();

  for (const userId of userIds) {
    batch.set(
      db.collection("user").doc(userId),
      {
        hasUnreadNotification: true,
        unreadGroupIds: admin.firestore.FieldValue.arrayUnion(groupId),
        lastNotificationAt: timestamp,
      },
      { merge: true }
    );
  }

  await batch.commit();
}

function stringifyMessageData(data) {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== undefined && value !== null)
      .map(([key, value]) => [key, String(value)])
  );
}

function chunkArray(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

async function deleteInvalidTokens(tokenEntries, responses) {
  const invalidTokenCodes = new Set([
    "messaging/invalid-registration-token",
    "messaging/registration-token-not-registered",
  ]);
  const deletePromises = [];

  responses.forEach((response, index) => {
    const code = response.error && response.error.code;
    if (code && invalidTokenCodes.has(code)) {
      deletePromises.push(tokenEntries[index].ref.delete());
    }
  });

  await Promise.all(deletePromises);
}
